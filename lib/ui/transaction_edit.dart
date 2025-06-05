import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class TransactionEdit extends StatefulWidget {
  const TransactionEdit(
      {super.key, required this.customer, required this.transaction});
  final Customer customer;
  final Transaction transaction;

  @override
  State<TransactionEdit> createState() => _TransactionEditState();
}

class _TransactionEditState extends State<TransactionEdit> {
  List<Transaction>? transactions;
  @override
  Widget build(BuildContext context) {
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    TextEditingController payControll =
        TextEditingController(text: widget.transaction.amount.toString());
    DatabaseController databaseController = Get.find();
    SettingsController settingsController = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: Text('New Transaction'.tr),
        actions: [
          TextButton.icon(
            onPressed: () {
              Get.defaultDialog(
                title: 'Alert',
                middleText:
                    'Are you sure to delete this transaction? there no way to recover just create new one!',
                cancel: TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: Text('Canecl')),
                onConfirm: () {
                  databaseController.objectBox.transactionBox
                      .remove(widget.transaction.id);
                  databaseController.loading();
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
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verSpace,
              TextFormField(
                controller: payControll,
                decoration: inputDecoration.copyWith(
                  label: Text('amount'.tr),
                ),
                keyboardType: TextInputType.number,
                validator: Validatorless.multiple([
                  Validatorless.required('required'.tr),
                  Validatorless.number('number'.tr),
                ]),
              ),
              verSpace,
              Divider(),
              verSpace,
              Row(
                children: [
                  Text('Customer Balance:'.tr),
                  Expanded(child: verSpace),
                  Text(settingsController
                      .currencyFormatter(widget.customer.balance()))
                ],
              ),
              verSpace,
              Divider(),
              verSpace,
              if (transactions != null)
                Expanded(
                  child: ListView.builder(
                      itemCount: transactions?.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                              '${settingsController.currencyFormatter(transactions![index].amount)}. ${transactions![index].paymentDate()}'),
                        );
                      }),
                ),
              verSpace,
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      widget.transaction.amount =
                          double.parse(payControll.text);
                      databaseController.objectBox.transactionBox
                          .put(widget.transaction);
                      databaseController.loading();
                      Get.back();
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
