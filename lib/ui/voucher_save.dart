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
  const VoucherSave({super.key, required this.voucher});
  final Voucher voucher;

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
        title: Text('Save Voucher'),
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
                  label: Text('Supplier'),
                ),
                keyboardType: TextInputType.number,
              ),
              verSpace,
              TextFormField(
                controller: payControll,
                decoration: inputDecoration.copyWith(
                  label: Text('payment amount'),
                ),
                keyboardType: TextInputType.number,
                validator: Validatorless.multiple([
                  Validatorless.required('this row is required!'),
                  Validatorless.number('number only'),
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
                            DataColumn(label: Text('Item')),
                            DataColumn(label: Text('Quantity')),
                            DataColumn(label: Text('Buy Price')),
                            DataColumn(label: Text('Sell Price')),
                            DataColumn(label: Text('Code')),
                            DataColumn(label: Text('Total Price')),
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
                  Text('Total Price:'),
                  Expanded(child: verSpace),
                  Text(settingsController
                      .currencyFormatter(widget.voucher.price())),
                ],
              ),
              verSpace,
              Row(
                children: [
                  Text('Supplier Balance:'),
                  Expanded(child: verSpace),
                  Text(settingsController
                      .currencyFormatter(widget.voucher.balance())),
                ],
              ),
              // verSpace,
              Row(
                children: [
                  Text('price to pay:'),
                  Expanded(child: verSpace),
                  Text(settingsController
                      .currencyFormatter(widget.voucher.price())),
                ],
              ),
              verSpace,
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
                  child: const Text('Save'),
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
