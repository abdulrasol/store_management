import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/item.dart';
import 'package:store_management/ui/items_add_save.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class VoucherSave extends StatefulWidget {
  const VoucherSave(
      {super.key, required this.oldQuantities, required this.newItems});

  final Map<String, int> oldQuantities;
  final List<Item> newItems;

  @override
  State<VoucherSave> createState() => _VoucherSaveState();
}

class _VoucherSaveState extends State<VoucherSave> {
  SettingsController settingsController = Get.find();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  DatabaseController databaseController = Get.find();

  @override
  Widget build(BuildContext context) {
    TextEditingController payControll = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Text('Save Voucher'.tr),
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verSpace,
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('item'.tr)),
                            DataColumn(label: Text('Supplier'.tr)),
                            DataColumn(label: Text('quantity'.tr)),
                            DataColumn(label: Text('Buy Price'.tr)),
                            DataColumn(label: Text('Sell Price'.tr)),
                            DataColumn(label: Text('Code'.tr)),
                            DataColumn(label: Text('Total Price'.tr)),
                          ],
                          rows: widget.newItems
                              .map<DataRow>((item) => DataRow(
                                    cells: [
                                      DataCell(Text(item.name)),
                                      DataCell(
                                          Text(item.supplier.target!.name)),
                                      DataCell(Text(
                                          item.quantity.toStringAsFixed(0))),
                                      DataCell(Text(item.buyPrice.toString())),
                                      DataCell(Text(item.sellPrice.toString())),
                                      DataCell(Text(item.code())),
                                      DataCell(Text(
                                          settingsController.currencyFormatter(
                                              item.buyPrice * item.quantity))),
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
                  Text(settingsController.currencyFormatter(widget.newItems
                      .fold(
                          0,
                          (previousValue, element) =>
                              previousValue +
                              (element.buyPrice * element.quantity)))),
                ],
              ),
              verSpace,
              verSpace,
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      for (Item item in widget.newItems) {
                        if (item.id != 0) {
                          item.quantity +=
                              databaseController.getItemById(item.id)!.quantity;
                        }
                        databaseController.addItem(item: item);
                      }

                      Get.to(() => VoucherView(
                            newItems: widget.newItems,
                          ));
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
