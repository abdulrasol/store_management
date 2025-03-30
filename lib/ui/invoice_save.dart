import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/profits.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/ui/customer_add.dart';
import 'package:store_management/ui/invoice_view.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class InvoiceSave extends StatefulWidget {
  const InvoiceSave({super.key, required this.invoice});
  final Invoice invoice;

  @override
  State<InvoiceSave> createState() => _InvoiceSaveState();
}

class _InvoiceSaveState extends State<InvoiceSave> {
  SettingsController settingsController = Get.find();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController customerNameControll = TextEditingController();
  TextEditingController payControll = TextEditingController();
  DatabaseController databaseController = Get.find();

  Customer? customer;

  @override
  Widget build(BuildContext context) {
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
              TypeAheadField<Customer>(
                controller: customerNameControll,
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: inputDecoration.copyWith(
                      label: Text('Custormer name'),
                      suffix: TextButton.icon(
                        onPressed: () async {
                          customer = await Get.to(() => CustomerAdd(),
                              arguments: customerNameControll.text);
                          customerNameControll.text = customer?.name ?? '';
                        },
                        label: Text('new customer'),
                        icon: Icon(Icons.person),
                      ),
                    ),
                  );
                },
                itemBuilder: (context, item) => ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.phone),
                ),
                onSelected: (item) {
                  setState(() {
                    customer = item;
                    customerNameControll.text = customer!.name;
                  });
                },
                suggestionsCallback: (text) {
                  return databaseController.custormers.where((custormer) {
                    return custormer.name
                        .toLowerCase()
                        .contains(text.toLowerCase());
                  }).toList();
                },
                emptyBuilder: (context) {
                  return ListTile(
                    title: Text(
                        'no customer found click to add ${customerNameControll.text}'),
                    onTap: () async {
                      customer = await Get.to(() => CustomerAdd(),
                          arguments: customerNameControll.text);
                      customerNameControll.text = customer?.name ?? '';
                    },
                  );
                },
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
                    if (formKey.currentState!.validate() &&
                        customer != null &&
                        customerNameControll.text.isNotEmpty) {
                      widget.invoice.customer.target = customer;
                      Transaction transactionSell = Transaction(
                          amount: (-1 * widget.invoice.pricetoPay()),
                          date: widget.invoice.date);
                      Transaction transactionPay = Transaction(
                          amount: double.tryParse(payControll.text) ?? 0,
                          date: widget.invoice.date);
                      transactionSell.customer.target =
                          widget.invoice.customer.target;
                      transactionPay.customer.target =
                          widget.invoice.customer.target;
                      widget.invoice.transactions
                          .addAll([transactionSell, transactionPay]);

                      Profits profit = Profits();
                      profit.invoice.target = widget.invoice;
                      //
                      databaseController.createInvoice(widget.invoice);
                      databaseController.generateProfit(profit);

                      Get.to(() => InvoiceView(invoice: widget.invoice));
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
