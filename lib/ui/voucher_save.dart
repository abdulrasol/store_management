import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/item.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/models/voucher.dart';
import 'package:store_management/ui/voucher_view.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class VoucherSave extends StatefulWidget {
  const VoucherSave(
      {super.key, required this.voucher, required this.oldQuantity});
  final Voucher voucher;
  final List<int> oldQuantity;

  @override
  State<VoucherSave> createState() => _VoucherSaveState();
}

class _VoucherSaveState extends State<VoucherSave> {
  SettingsController settingsController = Get.find();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  DatabaseController databaseController = Get.find();

  @override
  Widget build(BuildContext context) {
    Customer customer = widget.voucher.customer.target!;
    TextEditingController customerNameControll =
        TextEditingController(text: customer.name);
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
              TextFormField(
                enabled: false,
                controller: customerNameControll,
                decoration: inputDecoration.copyWith(
                  label: Text('Supplier'.tr),
                ),
                keyboardType: TextInputType.number,
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('item'.tr)),
                            DataColumn(label: Text('quantity'.tr)),
                            DataColumn(label: Text('Buy Price'.tr)),
                            DataColumn(label: Text('Sell Price'.tr)),
                            DataColumn(label: Text('Code'.tr)),
                            DataColumn(label: Text('Total Price'.tr)),
                          ],
                          rows: widget.voucher.items
                              .map<DataRow>((item) => DataRow(
                                    cells: [
                                      DataCell(Text(item.name)),
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
                  Text(settingsController
                      .currencyFormatter(widget.voucher.price())),
                ],
              ),
              verSpace,
              Row(
                children: [
                  Text('Supplier Balance'.tr),
                  Expanded(child: verSpace),
                  Text(settingsController
                      .currencyFormatter(widget.voucher.balance())),
                ],
              ),
              verSpace,
              Row(
                children: [
                  Text('price to pay'.tr),
                  Expanded(child: verSpace),
                  Text(settingsController
                      .currencyFormatter(widget.voucher.price())),
                ],
              ),
              verSpace,
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      for (Item item in widget.voucher.items) {
                        if (item.id != 0) {
                          item.quantity +=
                              databaseController.getItemById(item.id)!.quantity;
                        }
                        databaseController.addItem(item: item);
                      }
                      // create transactions
                      Transaction transactionSell = Transaction(
                          amount: (-1 * widget.voucher.price()),
                          date: widget.voucher.date.millisecondsSinceEpoch);
                      Transaction transactionPay = Transaction(
                          amount: double.tryParse(payControll.text) ?? 0,
                          date: widget.voucher.date.millisecondsSinceEpoch);
                      transactionSell.customer.target =
                          widget.voucher.customer.target;
                      transactionPay.customer.target =
                          widget.voucher.customer.target;
                      widget.voucher.transactions
                          .addAll([transactionSell, transactionPay]);

                      databaseController.createVouchers(widget.voucher);

                      Get.to(() => VoucherView(voucher: widget.voucher));
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
