import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/profits.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/ui/forms/customer_form.dart';
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
  TextEditingController discountControll = TextEditingController(text: '0');
  TextEditingController payControll = TextEditingController();
  DatabaseController databaseController = Get.find();

  Customer? customer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Save and Create invoice'.tr),
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
                      label: Text('custormer name'.tr),
                      suffix: TextButton.icon(
                        onPressed: () async {
                          customer = await Get.to(() => CustomerForm(),
                              arguments: customerNameControll.text);
                          customerNameControll.text = customer?.name ?? '';
                        },
                        label: Text('new customer'.tr),
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
                    title: Text('no customer found'
                        .trParams({'name': customerNameControll.text})),
                    onTap: () async {
                      customer = await Get.to(() => CustomerForm(),
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
                  label: Text('Payment Amount'.tr),
                ),
                keyboardType: TextInputType.number,
                validator: Validatorless.multiple([
                  Validatorless.required('required'.tr),
                  Validatorless.number('number'.tr),
                ]),
              ),
              verSpace,
              TextFormField(
                controller: discountControll,
                decoration: inputDecoration.copyWith(
                  label: Text('discount'.tr),
                ),
                keyboardType: TextInputType.number,
                validator: Validatorless.multiple([
                  Validatorless.required('required'.tr),
                  Validatorless.number('number'.tr),
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
                            DataColumn(label: Text('item'.tr)),
                            DataColumn(label: Text('Price'.tr)),
                            DataColumn(label: Text('quantity'.tr)),
                            //  DataColumn(label: Text('discount'.tr)),
                            DataColumn(label: Text('Total Price'.tr)),
                          ],
                          rows: widget.invoice.items
                              .map<DataRow>((item) => DataRow(
                                    cells: [
                                      DataCell(Text(item.itemName)),
                                      DataCell(
                                          Text(item.saledPrice().toString())),
                                      DataCell(Text(
                                          item.quantity.toStringAsFixed(0))),

                                      // DataCell(Text(
                                      //     item.discount.toStringAsFixed(0))),
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
                  Text('Total Price'.tr),
                  Expanded(child: verSpace),
                  Text(settingsController
                      .currencyFormatter(widget.invoice.price())),
                ],
              ),
              verSpace,
              Row(
                children: [
                  Text('discount'.tr),
                  Expanded(child: verSpace),
                  Text(settingsController
                      .currencyFormatter(widget.invoice.discount())),
                ],
              ),
              verSpace,
              Row(
                children: [
                  Text('price to pay'.tr),
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
                        date: widget.invoice.date,
                        type: 1,
                      );
                      Transaction transactionPay = Transaction(
                        amount: double.tryParse(payControll.text) ?? 0,
                        date: widget.invoice.date,
                        type: 2,
                      );
                      Transaction transactionDiscount = Transaction(
                        amount: (double.tryParse(discountControll.text) ?? 0),
                        date: widget.invoice.date,
                        type: 3,
                      );
                      transactionSell.customer.target =
                          widget.invoice.customer.target;
                      transactionPay.customer.target =
                          widget.invoice.customer.target;
                      transactionDiscount.customer.target =
                          widget.invoice.customer.target;
                      widget.invoice.transactions.addAll([
                        transactionSell,
                        transactionPay,
                        transactionDiscount
                      ]);

                      Profits profit = Profits();
                      profit.invoice.target = widget.invoice;
                      //
                      databaseController.createInvoice(widget.invoice);
                      databaseController.generateProfit(profit);

                      Get.to(() => InvoiceView(invoice: widget.invoice));
                    }
                  },
                  child: Text('save'.tr),
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
