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
import 'package:store_management/ui/voucher_save.dart';
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
  Voucher voucher = Voucher();
  Item? tempItem;
  Item? oldItem;
  Customer? customer;
  InvoiceItem? invoiceItem;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Items To Store'),
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
                    // TextFormField(
                    //   controller: nameControll,
                    //   decoration: inputDecoration.copyWith(
                    //     label: Text('Item Name'),
                    //   ),
                    //   keyboardType: TextInputType.text,
                    //   validator:
                    //       Validatorless.required('this row is required!'),
                    // ),
                    // verSpace,

                    TypeAheadField<Customer>(
                      controller: customerNameControll,
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: true,
                          decoration: inputDecoration.copyWith(
                            label: Text('Supplier'),
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
                          voucher.customer.target = item;
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
                          title: Text(
                              'no customer found click to add ${customerNameControll.text}'),
                          onTap: () async {
                            customer = await Get.to(() => SupplierAdd(),
                                arguments: customerNameControll.text);
                            customerNameControll.text = customer?.name ?? '';
                          },
                        );
                      },
                    ),
                    verSpace,
                    TextFormField(
                      controller: buyControll,
                      decoration: inputDecoration.copyWith(
                        label: Text('Buy Price'),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validatorless.multiple([
                        Validatorless.required('this row is required!'),
                        Validatorless.number('number only'),
                      ]),
                    ),
                    verSpace,
                    TextFormField(
                      controller: sellControll,
                      decoration: inputDecoration.copyWith(
                        label: Text('Sell Price'),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validatorless.multiple([
                        Validatorless.required('this row is required!'),
                        Validatorless.number('number only'),
                      ]),
                    ),
                    verSpace,
                    TextFormField(
                      controller: quaControll,
                      decoration: inputDecoration.copyWith(
                        label: Text('Quantity'),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validatorless.multiple([
                        Validatorless.required('this row is required!'),
                        Validatorless.number('number only'),
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
                          // create item
                          if (oldItem != null) {
                            tempItem = oldItem;
                            tempItem!.quantity = int.parse(quaControll.text);
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
                          }
                          // set supplier
                          tempItem!.supplier.target = customer!;
                          setState(() {
                            // save item to invoice
                            voucher.items.add(tempItem!);
                            // reset contorllers
                            nameControll.text = '';

                            buyControll.text = '';
                            sellControll.text = '';
                            quaControll.text = '';
                            tempItem = null;
                            invoiceItem = null;
                          });
                          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          //     content: Text(voucher
                          //         .items.last.item.target!.qunatity
                          //         .toString())));
                        }
                      },
                      child: Text('Add Item'))
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
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Buy Price')),
                        DataColumn(label: Text('Sell Price')),
                        DataColumn(label: Text('Total Price')),
                      ],
                      rows: voucher.items
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
                                          invoiceItem = null;
                                          voucher.items.remove(item);
                                        });
                                      },
                                      child: Icon(Icons.edit))),
                                  DataCell(Text(item.name)),
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
          if (voucher.items.isNotEmpty && customer != null) {
            voucher.customer.target = customer!;

            Get.to(() => VoucherSave(
                  voucher: voucher,
                ));
          }
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
