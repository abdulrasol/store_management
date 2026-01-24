import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/ui/forms/invoice_form.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:store_management/utils/printing/invoice_pdf.dart';
import 'package:store_management/utils/printing/save_pdf.dart';

class InvoiceView extends StatefulWidget {
  const InvoiceView({super.key, required this.invoice});
  final Invoice invoice;

  @override
  State<InvoiceView> createState() => _InvoiceViewState();
}

class _InvoiceViewState extends State<InvoiceView> {
  SettingsController settingsController = Get.find();
  DatabaseController databaseController = Get.find();

  @override
  Widget build(BuildContext context) {
    // Calculate totals dynamically
    double totalPaid = widget.invoice.transactions.where((t) => t.type == 2).fold(0.0, (sum, t) => sum + t.amount);

    double priceToPay = widget.invoice.pricetoPay();
    double remaining = priceToPay - totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text('invoice-id'.trParams({'id': widget.invoice.id.toString()})),
        leading: IconButton(
            onPressed: () {
              if (Get.previousRoute == '/InvoiceSave' || Get.previousRoute == '/InvoiceSaveUpdate') {
                Get.close(3);
              }
              Get.back();
            },
            icon: Icon(Icons.arrow_back)),
        actions: [
          IconButton(
            tooltip: 'Edit Invoice'.tr,
            onPressed: () async {
              await Get.to(() => InvoiceForm(invoice: widget.invoice));
              setState(() {}); // Refresh view after edit
            },
            icon: Icon(Icons.edit_square),
          ),
          if (!GetPlatform.isDesktop)
            IconButton(
              onPressed: () async {
                await sharePdfFile(await generateInvoice(invoice: widget.invoice), widget.invoice.customer.target?.name, widget.invoice.id);
              },
              icon: Icon(Icons.share_outlined),
            ),
          IconButton(
              onPressed: () async {
                await printPdfFileToStorage(await generateInvoice(invoice: widget.invoice));
              },
              icon: Icon(Icons.print))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Text('customer_name'.trParams({'name': widget.invoice.customer.target?.name ?? ''})),
                Text(widget.invoice.invoiceDate()),
                Text(widget.invoice.invoiceNumber()),
              ],
            ),
            verSpace,
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('item'.tr)),
                          DataColumn(label: Text('Price'.tr)),
                          DataColumn(label: Text('quantity'.tr)),
                          DataColumn(label: Text('Total Price'.tr)),
                        ],
                        rows: widget.invoice.items
                            .map<DataRow>((item) => DataRow(
                                  cells: [
                                    DataCell(Text(item.itemName)),
                                    DataCell(Text(settingsController.currencyFormatter(item.saledPrice()))),
                                    DataCell(Text(item.quantity.toStringAsFixed(0))),
                                    DataCell(Text(settingsController.currencyFormatter(item.totalPrice()))),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(),
            _buildSummaryRow('Total Price'.tr, widget.invoice.price()),
            verSpace,
            _buildSummaryRow('discount'.tr, widget.invoice.discount()),
            verSpace,
            _buildSummaryRow('price to pay'.tr, priceToPay),
            verSpace,
            _buildSummaryRow('Total Paid'.tr, totalPaid, color: Colors.green),
            verSpace,
            _buildSummaryRow((remaining > 0 ? 'Remaining' : 'Change').tr, remaining.abs(), color: remaining > 0 ? Colors.red : Colors.blue),
            verSpace,
            if (remaining > 0)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _addPayment(remaining),
                  icon: Icon(Icons.payment),
                  label: Text("Add Payment".tr),
                ),
              ),
            verSpace,
            verSpace,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {Color? color}) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Expanded(child: verSpace),
        Text(settingsController.currencyFormatter(amount), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _addPayment(double remaining) {
    TextEditingController amountController = TextEditingController(text: remaining.toString());
    Get.defaultDialog(
        title: "Add Payment".tr,
        content: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Amount".tr),
            ),
          ],
        ),
        textConfirm: "Pay".tr,
        textCancel: "Cancel".tr,
        onConfirm: () {
          double amount = double.tryParse(amountController.text) ?? 0;
          if (amount > 0) {
            Transaction t = Transaction(
              date: DateTime.now().millisecondsSinceEpoch,
              amount: amount,
              type: 2, // Payment
            );
            t.customer.target = widget.invoice.customer.target;
            t.invoice.target = widget.invoice; // Link to Invoice

            databaseController.newTransaction(t);

            // Also link to invoice list in memory
            widget.invoice.transactions.add(t);
            databaseController.objectBox.invoiceBox.put(widget.invoice); // Ensure persistence of link

            setState(() {}); // Refresh UI
            Get.back();
          }
        });
  }
}
