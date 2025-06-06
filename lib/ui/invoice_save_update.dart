import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/ui/invoice_view.dart';

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
    Transaction disTran = Transaction(date: widget.invoice.date, amount: 0);

    try {
      
      disTran = widget.invoice.transactions[2];
    } catch (e) {
      print(e);
    }

    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    TextEditingController customerNameControll =
        TextEditingController(text: widget.invoice.customer.target?.name);
    TextEditingController payControll = TextEditingController(
        text: widget.invoice.transactions[1].amount.toString());

    TextEditingController discountControll =
        TextEditingController(text: disTran.amount.toString());
    return Scaffold(
      appBar: AppBar(
        title: Text('Save invoice edits'.tr),
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
                  label: Text('custormer name'.tr),
                ),
                keyboardType: TextInputType.number,
              ),
              verSpace,
              TextFormField(
                controller: payControll,
                decoration: inputDecoration.copyWith(
                  label: Text('payment amount'.tr),
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
                    if (formKey.currentState!.validate()) {
                      databaseController.updateInvoice(
                          oldItemsMap: widget.oldItemMap,
                          invoice: widget.invoice,
                          paymentAmount: double.tryParse(payControll.text) ?? 0,
                          discount:
                              double.tryParse(discountControll.text) ?? 0);

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
