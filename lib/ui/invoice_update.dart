import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/invoice_item.dart';
import 'package:store_management/models/item.dart';
import 'package:store_management/ui/invoice_save_update.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class InvoiceUpdate extends StatefulWidget {
  const InvoiceUpdate({super.key, required this.invoice});
  final Invoice invoice;

  @override
  State<InvoiceUpdate> createState() => _InvoiceUpdateState();
}

class _InvoiceUpdateState extends State<InvoiceUpdate> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController nameControll = TextEditingController();
  TextEditingController quantityControll = TextEditingController(text: '1');
  TextEditingController discountControll = TextEditingController(text: '0');
  SettingsController settingsController = Get.find();
  DatabaseController databaseController = Get.find();
  Item? tempItem;
  InvoiceItem? tempInvoiceItem;
  bool editng = false;

  late final Map<String, Map<String, dynamic>> oldItemMap;

  @override
  void initState() {
    super.initState();

    oldItemMap = {
      for (var item in widget.invoice.items)
        item.itemName: {
          'quantity': item.quantity,
          'id': item.item.targetId,
          'total-quantity': item.item.target!.quantity
        }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Invoice'),
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
                      //print(item.toMap());
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
                            // get and discount
                            double quantity =
                                double.tryParse(quantityControll.text) ??
                                    double.parse('${quantityControll.text}.0');

                            double discount =
                                double.tryParse(discountControll.text) ??
                                    double.parse('${discountControll.text}.0');

                            if (formKey.currentState!.validate()) {
                              if (tempItem != null && nameControll.text != '') {
                                tempInvoiceItem != null
                                    ? updateItem(quantity.toInt(), discount)
                                    : addItem(quantity, discount);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Select item!')));
                              }
                            }
                          },
                          child:
                              Text(tempInvoiceItem != null ? 'Update' : 'Add'))
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
                          DataColumn(label: Text('Update Action')),
                          DataColumn(label: Text('Item')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Discount')),
                          DataColumn(label: Text('Total Price')),
                        ],
                        rows: widget.invoice.items
                            .map<DataRow>((item) => DataRow(
                                  cells: [
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                            tooltip:
                                                'edit quantity, discout or anything',
                                            onPressed: () {
                                              setState(() {
                                                tempInvoiceItem = item;
                                                tempItem = item.item.target;
                                                nameControll.text =
                                                    item.itemName;
                                                quantityControll.text =
                                                    item.quantity.toString();
                                                discountControll.text =
                                                    item.discount.toString();
                                              });
                                            },
                                            icon: Icon(Icons.edit)),
                                        horSpace,
                                        IconButton(
                                          tooltip:
                                              'remove item fron this invoive',
                                          onPressed: () {
                                            setState(() {
                                              widget.invoice.items.remove(item);
                                            });
                                          },
                                          icon: Icon(Icons.delete),
                                        ),
                                      ],
                                    )),
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
          if (widget.invoice.items.isNotEmpty) {
            Get.to(() => InvoiceSaveUpdate(
                  oldItemMap: oldItemMap,
                  invoice: widget.invoice,
                ));
          }
        },
        child: Text('Next'),
      ),
    );
  }

  @override
  void deactivate() {
    super.deactivate();
    databaseController.loading();
  }

  void addItem(quantity, discount) {
    // check if item alrady add

    // InvoiceItem? checkInvoiceItem = widget.invoice.items.firstWhereOrNull((i) {
    //   return i.item.targetId == tempItem!.id;
    // });
    bool isAddbefore = false;
    for (InvoiceItem item in widget.invoice.items) {
      if (tempItem!.code == item.item.target!.code) {
        isAddbefore = true;
        break;
      }
    }

    if (!isAddbefore) {
      // item not add until now
      if (quantity <= tempItem!.quantity) {
        setState(() {
          tempInvoiceItem = InvoiceItem(
            discount: double.tryParse(discountControll.text) ??
                double.parse('${discountControll.text}.0'),
            quantity: int.parse(quantityControll.text),
            itemName: tempItem!.name,
            itemSellPrice: tempItem!.sellPrice,
          );
          tempInvoiceItem!.item.target = tempItem;
          widget.invoice.items.add(tempInvoiceItem!);
          discountControll.text = '0';
          nameControll.text = '';
          quantityControll.text = '0';
          tempInvoiceItem = null;
          tempItem = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Qunatity of ${tempItem!.name} less than you want!')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: TextButton(
            onPressed: () {
              // setState(() {
              //   tempInvoiceItem = checkInvoiceItem;
              //   tempItem = checkInvoiceItem.item.target;
              //   nameControll.text = checkInvoiceItem.itemName;
              //   quantityControll.text = checkInvoiceItem.quantity.toString();
              //   discountControll.text = checkInvoiceItem.discount.toString();
              // });
            },
            child: Text(
                '{checkInvoiceItem.itemName} already added! click to pencel edit')),
      ));
    }
  }

  // void updateItem(quantity, discount) {
  //   if ((quantity - tempInvoiceItem!.quantity) <= tempItem!.qunatity) {
  //     int index = widget.invoice.items.indexOf(tempInvoiceItem);
  //     tempInvoiceItem?.discount = discount;
  //     tempInvoiceItem!.quantity = quantity;
  //     setState(() {
  //       nameControll.text = '';
  //       quantityControll.text = '0';
  //       discountControll.text = '0';
  //       widget.invoice.items[index] = tempInvoiceItem!;
  //       tempItem = null;
  //       tempInvoiceItem = null;
  //     });
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //         content: Text('Qunatity of ${tempItem!.name} less than you want!')));
  //   }
  // }
  void updateItem(int quantity, discount) {
    if ((quantity - tempInvoiceItem!.quantity) <= tempItem!.quantity) {
      int index = widget.invoice.items.indexOf(tempInvoiceItem);
      tempItem!.quantity +=
          tempInvoiceItem!.quantity.toInt(); // إعادة الكمية القديمة
      tempItem!.quantity -= quantity; // خصم الكمية الجديدة
      tempInvoiceItem?.discount = discount;
      tempInvoiceItem!.quantity = quantity;
      setState(() {
        nameControll.text = '';
        quantityControll.text = '0';
        discountControll.text = '0';
        widget.invoice.items[index] = tempInvoiceItem!;
      });
      databaseController.objectBox.itemBox.put(tempItem!); // تحديث المخزون
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Qunatity of ${tempItem!.name} less than you want!')));
    }
    tempItem = null;
    tempInvoiceItem = null;
  }
}
