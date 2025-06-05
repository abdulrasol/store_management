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
  TextEditingController sellPriceControll = TextEditingController();
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
        title: Text('Update Invoice'.tr),
        actions: [
          TextButton.icon(
            onPressed: () {
              Get.defaultDialog(
                title: 'Alert',
                middleText:
                    'Are you sure to delete this invoice? there no way to recover just create new one!',
                onCancel: () {},
                cancel: TextButton(onPressed: () {}, child: Text('Canecl')),
                onConfirm: () {
                  databaseController.deleteInvoice(widget.invoice);
                  Get.close(3);
                },
                textConfirm: 'Delete',
              );
            },
            icon: Icon(
              Icons.delete_forever,
              color: Colors.red,
            ),
            label: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
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
                      //print(item.toMap());
                      setState(() {
                        nameControll.text = item.name;
                        tempItem = item;
                        sellPriceControll.text = item.sellPrice.toString();
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
                            // get and discount
                            int quantity =
                                int.tryParse(quantityControll.text) ??
                                    int.parse('${quantityControll.text}.0');

                            double discount = 0;
                            double sellPriceInput =
                                double.parse(sellPriceControll.text);

                            if (sellPriceInput < tempItem!.sellPrice) {
                              discount = tempItem!.sellPrice -
                                  double.parse(sellPriceControll.text);
                            } else {
                              discount = 0;
                            }

                            if (formKey.currentState!.validate()) {
                              if (tempItem != null && nameControll.text != '') {
                                tempInvoiceItem != null
                                    ? updateItem(quantity.toInt(), discount,
                                        sellPriceInput)
                                    : addItem(
                                        quantity, discount, sellPriceInput);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Select item!'.tr)));
                              }
                            }
                          },
                          child: Text(
                              tempInvoiceItem != null ? 'Update'.tr : 'Add'.tr))
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
                          //    DataColumn(label: Text('discount'.tr)),
                          DataColumn(label: Text('Total Price'.tr)),
                        ],
                        rows: widget.invoice.items
                            .map<DataRow>((item) => DataRow(
                                  cells: [
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                            tooltip:
                                                'edit quantity, discout or anything'
                                                    .tr,
                                            onPressed: () {
                                              setState(() {
                                                tempInvoiceItem = item;
                                                tempItem = item.item.target;
                                                nameControll.text =
                                                    item.itemName;
                                                quantityControll.text =
                                                    item.quantity.toString();
                                                sellPriceControll.text = item
                                                    .saledPrice()
                                                    .toString();
                                              });
                                            },
                                            icon: Icon(Icons.edit)),
                                        horSpace,
                                        IconButton(
                                          tooltip:
                                              'remove item fron this invoive'
                                                  .tr,
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
          if (widget.invoice.items.isNotEmpty) {
            Get.to(() => InvoiceSaveUpdate(
                  oldItemMap: oldItemMap,
                  invoice: widget.invoice,
                ));
          }
        },
        child: Text('Next'.tr),
      ),
    );
  }

  @override
  void deactivate() {
    super.deactivate();
    databaseController.loading();
  }

  void addItem(quantity, discount, sellPrice) {
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
            discount: discount,
            quantity: quantity,
            itemName: tempItem!.name,
            itemSellPrice: sellPrice,
          );
          tempInvoiceItem!.item.target = tempItem;
          widget.invoice.items.add(tempInvoiceItem!);
          sellPriceControll.text = '0';
          nameControll.text = '';
          quantityControll.text = '0';
          tempInvoiceItem = null;
          tempItem = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('less-Qunatity'.trParams({'item': tempItem!.name}))));
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
            child: Text('already added'
                .trParams({'name': tempInvoiceItem?.itemName ?? ''}))),
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
  void updateItem(int quantity, discount, sellPrice) {
    if ((quantity - tempInvoiceItem!.quantity) <= tempItem!.quantity) {
      int index = widget.invoice.items.indexOf(tempInvoiceItem);
      tempItem!.quantity +=
          tempInvoiceItem!.quantity.toInt(); // إعادة الكمية القديمة
      tempItem!.quantity -= quantity; // خصم الكمية الجديدة
      tempInvoiceItem?.discount = discount;
      tempInvoiceItem!.quantity = quantity;
      tempInvoiceItem!.itemSellPrice = sellPrice;
      setState(() {
        nameControll.text = '';
        quantityControll.text = '0';
        sellPriceControll.text = '0';
        widget.invoice.items[index] = tempInvoiceItem!;
      });
      databaseController.objectBox.itemBox.put(tempItem!); // تحديث المخزون
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('less-Qunatity'.trParams({'item': tempItem!.name}))));
    }
    tempItem = null;
    tempInvoiceItem = null;
  }
}
