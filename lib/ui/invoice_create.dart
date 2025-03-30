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
  TextEditingController discountControll = TextEditingController(text: '0');
  SettingsController settingsController = Get.find();
  DatabaseController databaseController = Get.find();
  Item? tempItem;

  Invoice invoice = Invoice();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create new invoice'),
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
                  Text('search for item'),
                  verSpace,
                  TypeAheadField<Item>(
                    controller: nameControll,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: true,
                        decoration:
                            inputDecoration.copyWith(label: Text('item')),
                      );
                    },
                    itemBuilder: (context, item) => ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                          '${settingsController.currencyFormatter(item.sellPrice)}, ${item.quantity} available'),
                    ),
                    onSelected: (item) {
                      setState(() {
                        nameControll.text = item.name;
                        tempItem = item;
                      });
                    },
                    suggestionsCallback: (text) {
                      return databaseController.items.where((item) {
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
                          controller: quantityControll,
                          decoration: inputDecoration.copyWith(
                            label: Text('quantity'),
                          ),
                          keyboardType: TextInputType.number,
                          validator: Validatorless.multiple([
                            Validatorless.required('this row is required!'),
                            Validatorless.number('number only'),
                          ]),
                        ),
                      ),
                      horSpace,
                      Expanded(
                        child: TextFormField(
                          controller: discountControll,
                          decoration: inputDecoration.copyWith(
                            label: Text('discount'),
                          ),
                          keyboardType: TextInputType.number,
                          validator: Validatorless.multiple([
                            Validatorless.required('this row is required!'),
                            Validatorless.number('number only'),
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
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      'Qunatity of ${tempItem!.name} less than you want!')));
                            } else {
                              if (formKey.currentState!.validate() &&
                                  tempItem != null) {
                                setState(
                                  () {
                                    var item = InvoiceItem(
                                      discount: double.tryParse(
                                              discountControll.text) ??
                                          double.parse(
                                              '${discountControll.text}.0'),
                                      quantity:
                                          int.parse(quantityControll.text),
                                      itemName: tempItem!.name,
                                    
                                      itemSellPrice: tempItem!.sellPrice,
                                    );
                                    item.item.target = tempItem;
                                    invoice.items.add(item);
                                    discountControll.text = '0';
                                    nameControll.text = '';
                                    quantityControll.text = '1';
                                   
                                  },
                                );
                              }
                            }
                          },
                          child: Text('Add'))
                    ],
                  ),
                ],
              ),
            ),
            verSpace,
            Divider(),
            verSpace,
            Text('Invoice Items'),
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
                          DataColumn(label: Text('Item')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Discount')),
                          DataColumn(label: Text('Total Price')),
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
                                        Text(item.quantity.toStringAsFixed(0))),
                                    DataCell(
                                        Text(item.itemSellPrice.toString())),
                                    DataCell(
                                        Text(item.discount.toStringAsFixed(0))),
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
        child: Text('Next'),
      ),
    );
  }
}
