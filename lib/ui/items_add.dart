import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/invoice_item.dart';
import 'package:store_management/models/item.dart';
import 'package:store_management/models/voucher.dart';
import 'package:store_management/ui/supplier_add.dart';
import 'package:store_management/ui/items_add_view.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class VoucherCreate extends StatefulWidget {
  const VoucherCreate({super.key});

  @override
  State<VoucherCreate> createState() => _VoucherCreateState();
}

class _VoucherCreateState extends State<VoucherCreate> {
  DatabaseController databaseController = Get.find();
  SettingsController settingsController = Get.find();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController nameControll = TextEditingController();
  TextEditingController fromControll = TextEditingController();
  TextEditingController buyControll = TextEditingController();
  TextEditingController sellControll = TextEditingController();
  TextEditingController quaControll = TextEditingController();
  TextEditingController customerNameControll = TextEditingController();

  Item? tempItem;
  Item? oldItem;
  Customer? customer;
  Map<String, int> oldQuantities = {};
  List<Item> newItems = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Items, New Voucher'.tr),
        actions: [Icon(Icons.add_shopping_cart), horSpace],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: formKey,
                child: Column(
                  children: [
                    verSpace,
                    // item select, search old or add new item
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
                          oldItem = item;
                          sellControll.text = oldItem!.sellPrice.toString();
                          buyControll.text = oldItem!.buyPrice.toString();
                          buyControll.text = oldItem!.buyPrice.toString();
                          customerNameControll.text =
                              oldItem!.supplier.target?.name ?? '';
                          customer = oldItem?.supplier.target;
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
                    // Supplers find or add new
                    TypeAheadField<Customer>(
                      controller: customerNameControll,
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: true,
                          decoration: inputDecoration.copyWith(
                            label: Text('Supplier'.tr),
                            suffix: TextButton.icon(
                              onPressed: () async {
                                customer = await Get.to(() => SupplierAdd(),
                                    arguments: customerNameControll.text);
                                customerNameControll.text =
                                    customer?.name ?? '';
                              },
                              label: Text('new supplier'.tr),
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
                        return databaseController.suppliers.where((custormer) {
                          return custormer.name
                              .toLowerCase()
                              .contains(text.toLowerCase());
                        }).toList();
                      },
                      emptyBuilder: (context) {
                        return ListTile(
                          title: Text('no-supplier'.trParams(
                              {'supplier': customerNameControll.text})),
                          onTap: () async {
                            customer = await Get.to(() => SupplierAdd(),
                                arguments: customerNameControll.text);
                            customerNameControll.text = customer?.name ?? '';
                          },
                        );
                      },
                    ),
                    verSpace,
                    // item buy prcie
                    TextFormField(
                      controller: buyControll,
                      decoration: inputDecoration.copyWith(
                        label: Text('Buy Price'),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validatorless.multiple([
                        Validatorless.required('required'.tr),
                        Validatorless.number('number'.tr),
                      ]),
                    ),
                    verSpace,
                    // sell price
                    TextFormField(
                      controller: sellControll,
                      decoration: inputDecoration.copyWith(
                        label: Text('Sell Price'.tr),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validatorless.multiple([
                        Validatorless.required('required'.tr),
                        Validatorless.number('number'.tr),
                      ]),
                    ),
                    verSpace,
                    // item quantity
                    TextFormField(
                      controller: quaControll,
                      decoration: inputDecoration.copyWith(
                        label: Text('quantity'.tr),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validatorless.multiple([
                        Validatorless.required('required'.tr),
                        Validatorless.number('number'.tr),
                      ]),
                    ),
                  ],
                ),
              ),
              verSpace,
              Row(
                children: [
                  Text(
                    'items'.tr,
                  ),
                  horSpace,
                  Expanded(
                    child: const Divider(),
                  ),
                  TextButton(
                      onPressed: () {
                        if (formKey.currentState!.validate() &&
                            customer != null &&
                            customerNameControll.text.isNotEmpty) {
                          double newPirce = double.tryParse(buyControll.text) ??
                              double.parse('${buyControll.text}.0');
                          if (oldItem != null &&
                              oldItem!.supplier.targetId == customer!.id &&
                              oldItem!.buyPrice == newPirce) {
                            tempItem = oldItem;
                            int oldQuantity = oldItem!.quantity;
                            tempItem!.quantity = int.parse(quaControll.text);
                            oldQuantities.addAll({tempItem!.name: oldQuantity});
                          } else {
                            tempItem = Item(
                              name: nameControll.text,
                              buyPrice: double.tryParse(buyControll.text) ??
                                  double.parse('${buyControll.text}.0'),
                              sellPrice: double.tryParse(sellControll.text) ??
                                  double.parse('${sellControll.text}.0'),
                              quantity: int.tryParse(quaControll.text) ??
                                  int.parse(quaControll.text),
                            );
                            oldQuantities.addAll({tempItem!.name: 0});
                          }
                          // set supplier
                          tempItem!.supplier.target = customer!;
                          setState(() {
                            // save item to invoice

                            newItems.add(tempItem!);
                            //  Item.add(tempItem!);
                            // reset contorllers
                            nameControll.text = '';
                            buyControll.text = '';
                            sellControll.text = '';
                            quaControll.text = '';
                            tempItem = null;
                          });
                          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          //     content: Text(voucher
                          //         .items.last.item.target!.qunatity
                          //         .toString())));
                        }
                      },
                      child: Text('Add'.tr))
                ],
              ),
              verSpace,
              Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('item'.tr)),
                        DataColumn(label: Text('Supplier'.tr)),
                        DataColumn(label: Text('quantity'.tr)),
                        DataColumn(label: Text('Buy Price'.tr)),
                        DataColumn(label: Text('Sell Price'.tr)),
                        DataColumn(label: Text('Total Price'.tr)),
                      ],
                      rows: newItems
                          .map<DataRow>((item) => DataRow(
                                cells: [
                                  DataCell(InkWell(
                                      onTap: () {
                                        setState(() {
                                          nameControll.text = item.name;

                                          buyControll.text =
                                              item.buyPrice.toString();
                                          sellControll.text =
                                              item.sellPrice.toString();
                                          quaControll.text =
                                              item.quantity.toString();
                                          tempItem = null;

                                          newItems.remove(item);
                                        });
                                      },
                                      child: Icon(Icons.edit))),
                                  DataCell(Text(item.name)),
                                  DataCell(Text(item.supplier.target!.name)),
                                  DataCell(
                                      Text(item.quantity.toStringAsFixed(0))),
                                  DataCell(Text(settingsController
                                      .currencyFormatter(item.buyPrice))),
                                  DataCell(Text(settingsController
                                      .currencyFormatter(item.sellPrice))),
                                  DataCell(
                                    Text(
                                      settingsController.currencyFormatter(
                                          item.buyPrice * item.quantity),
                                    ),
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (newItems.isNotEmpty) {
            Get.to(() => VoucherSave(
                  newItems: newItems,
                  oldQuantities: oldQuantities,
                ));
          }
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
