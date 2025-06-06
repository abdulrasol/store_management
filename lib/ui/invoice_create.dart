import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/invoice_item.dart';
import 'package:store_management/models/item.dart';
import 'package:store_management/ui/invoice_save.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class InvoiceCreate extends StatefulWidget {
  const InvoiceCreate({super.key});

  @override
  State<InvoiceCreate> createState() => _InvoiceCreateState();
}

class _InvoiceCreateState extends State<InvoiceCreate> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController nameControll = TextEditingController();
  TextEditingController quantityControll = TextEditingController(text: '1');
  TextEditingController sellPriceControll = TextEditingController(text: '0');
  SettingsController settingsController = Get.find();
  DatabaseController databaseController = Get.find();
  Item? tempItem;

  Invoice invoice = Invoice();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Invoice'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Item'.tr),
                  verSpace,
                  TypeAheadField<Item>(
                    controller: nameControll,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: true,
                        decoration:
                            inputDecoration.copyWith(label: Text('item'.tr)),
                      );
                    },
                    itemBuilder: (context, item) => ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                          '${settingsController.currencyFormatter(item.sellPrice)}, ${item.quantity} ${'available'.tr}'),
                    ),
                    onSelected: (item) {
                      setState(() {
                        nameControll.text = item.name;
                        tempItem = item;
                        sellPriceControll.text = item.sellPrice.toString();
                      });
                    },
                    suggestionsCallback: (text) {
                      return databaseController.items
                          .where((item) => item.quantity > 0)
                          .toList()
                          .where((item) {
                        return item.name
                            .toLowerCase()
                            .contains(text.toLowerCase());
                      }).toList();
                    },
                  ),
                  verSpace,
                  verSpace,
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: sellPriceControll,
                          decoration: inputDecoration.copyWith(
                            label: Text('Sell Price'.tr),
                          ),
                          keyboardType: TextInputType.number,
                          validator: Validatorless.multiple([
                            Validatorless.required('required'.tr),
                            Validatorless.number('number'.tr),
                          ]),
                        ),
                      ),
                      horSpace,
                      Expanded(
                        child: TextFormField(
                          controller: quantityControll,
                          decoration: inputDecoration.copyWith(
                            label: Text('quantity'.tr),
                          ),
                          keyboardType: TextInputType.number,
                          validator: Validatorless.multiple([
                            Validatorless.required('required'.tr),
                            Validatorless.number('number'.tr),
                          ]),
                        ),
                      ),
                      horSpace,
                      OutlinedButton(
                          onPressed: () {
                            if (tempItem != null &&
                                tempItem!.quantity <
                                    double.parse(
                                        '${quantityControll.text}.0')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('less-Qunatity'.trParams(
                                          {'item': tempItem!.name}))));
                            } else {
                              if (formKey.currentState!.validate() &&
                                  tempItem != null) {
                                double discount = 0;
                                double sellPriceInput =
                                    double.parse(sellPriceControll.text);

                                if (sellPriceInput < tempItem!.sellPrice) {
                                  discount = tempItem!.sellPrice -
                                      double.parse(sellPriceControll.text);
                                } else {
                                  discount = 0;
                                }

                                setState(
                                  () {
                                    var item = InvoiceItem(
                                      discount: discount,
                                      quantity:
                                          int.parse(quantityControll.text),
                                      itemName: tempItem!.name,
                                      itemSellPrice: sellPriceInput,
                                    );
                                    item.item.target = tempItem;
                                    invoice.items.add(item);
                                    sellPriceControll.text = '0';
                                    nameControll.text = '';
                                    quantityControll.text = '1';
                                    print(sellPriceInput);
                                    print(item.itemSellPrice);
                                    print(item.saledPrice());
                                  },
                                );
                              }
                            }
                          },
                          child: Text('Add'.tr))
                    ],
                  ),
                ],
              ),
            ),
            verSpace,
            Divider(),
            verSpace,
            Text('Invoice Items'.tr),
            verSpace,
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('item'.tr)),

                          DataColumn(label: Text('Price'.tr)),
                          DataColumn(label: Text('quantity'.tr)),
                          //  DataColumn(label: Text('discount'.tr)),
                          DataColumn(label: Text('Total Price'.tr)),
                        ],
                        rows: invoice.items
                            .map<DataRow>((item) => DataRow(
                                  cells: [
                                    DataCell(InkWell(
                                        onTap: () {
                                          setState(() {
                                            invoice.items.remove(item);
                                          });
                                        },
                                        child: Icon(Icons.delete_forever))),
                                    DataCell(Text(item.item.target!.name)),
                                    DataCell(
                                        Text(item.saledPrice().toString())),
                                    DataCell(
                                        Text(item.quantity.toStringAsFixed(0))),

                                    // DataCell(
                                    //     Text(item.discount.toStringAsFixed(0))),
                                    DataCell(Text(
                                        item.totalPrice().toStringAsFixed(0))),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (invoice.items.isNotEmpty) {
            Get.to(() => InvoiceSave(invoice: invoice));
          }
        },
        child: Text('Next'.tr),
      ),
    );
  }
}
