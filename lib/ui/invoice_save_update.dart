import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/invoice.dart';

import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class InvoiceSaveUpdate extends StatefulWidget {
  const InvoiceSaveUpdate({
    super.key,
    required this.invoice,
    required this.oldItemMap,
  });

  final Invoice invoice;
  final Map<String, Map<String, dynamic>> oldItemMap;

  @override
  State<InvoiceSaveUpdate> createState() => _InvoiceSaveUpdateState();
}

class _InvoiceSaveUpdateState extends State<InvoiceSaveUpdate> {
  SettingsController settingsController = Get.find();

  DatabaseController databaseController = Get.find();

  Customer? customer;

  @override
  Widget build(BuildContext context) {
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    TextEditingController customerNameControll =
        TextEditingController(text: widget.invoice.customer.target?.name);
    TextEditingController payControll = TextEditingController(
        text: widget.invoice.transactions[1].amount.toString());
    return Scaffold(
      appBar: AppBar(
        title: Text('Save and Create invoice'),
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verSpace,
              TextFormField(
                enabled: false,
                controller: customerNameControll,
                decoration: inputDecoration.copyWith(
                  label: Text('Supplier'),
                ),
                keyboardType: TextInputType.number,
              ),
              verSpace,
              TextFormField(
                controller: payControll,
                decoration: inputDecoration.copyWith(
                  label: Text('payment amount'),
                ),
                keyboardType: TextInputType.number,
                validator: Validatorless.multiple([
                  Validatorless.required('this row is required!'),
                  Validatorless.number('number only'),
                ]),
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
                            DataColumn(label: Text('Item')),
                            DataColumn(label: Text('Quantity')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Discount')),
                            DataColumn(label: Text('Total Price')),
                          ],
                          rows: widget.invoice.items
                              .map<DataRow>((item) => DataRow(
                                    cells: [
                                      DataCell(Text(item.itemName)),
                                      DataCell(Text(
                                          item.quantity.toStringAsFixed(0))),
                                      DataCell(
                                          Text(item.itemSellPrice.toString())),
                                      DataCell(Text(
                                          item.discount.toStringAsFixed(0))),
                                      DataCell(Text(item
                                          .totalPrice()
                                          .toStringAsFixed(0))),
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
              Row(
                children: [
                  Text('Total Price:'),
                  Expanded(child: verSpace),
                  Text(settingsController
                      .currencyFormatter(widget.invoice.price())),
                ],
              ),
              verSpace,
              Row(
                children: [
                  Text('Discount:'),
                  Expanded(child: verSpace),
                  Text(settingsController
                      .currencyFormatter(widget.invoice.discount())),
                ],
              ),
              verSpace,
              Row(
                children: [
                  Text('price to pay:'),
                  Expanded(child: verSpace),
                  Text(settingsController
                      .currencyFormatter(widget.invoice.pricetoPay())),
                ],
              ),
              verSpace,
              verSpace,
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // Profits profit = databaseController.profits.firstWhere(
                      //     (profit) =>
                      //         profit.invoice.target! == widget.orginalInvoice);
                      // profit.invoice.target = widget.updatedInvoice;
                      //
                      databaseController.updateInvoice(
                          oldItemsMap: widget.oldItemMap,
                          invoice: widget.invoice,
                          paymentAmount:
                              double.tryParse(payControll.text) ?? 0);

                      // databaseController.generateProfit(profit);

                      // Get.to(() => InvoiceView(invoice: widget.updatedInvoice));
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
              verSpace
            ],
          ),
        ),
      ),
    );
  }
}
