import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/expense.dart';

import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class ExpenseAdd extends StatefulWidget {
  const ExpenseAdd({super.key});

  @override
  State<ExpenseAdd> createState() => _ExpenseAddState();
}

class _ExpenseAddState extends State<ExpenseAdd> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController descControll = TextEditingController();
  TextEditingController amountControll = TextEditingController();
  TextEditingController dateControll = TextEditingController();
  DatabaseController databaseController = Get.find();
  SettingsController settingsController = Get.find();
  DateTime? picker = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Expense'.tr),
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verSpace,

              //   },
              //   suggestionsCallback: (text) {
              //     List<Customer> customers = [];
              //     customers = [
              //       ...databaseController.custormers,
              //       ...databaseController.suppliers
              //     ];
              //     return customers.where((custormer) {
              //       return custormer.name
              //           .toLowerCase()
              //           .contains(text.toLowerCase());
              //     }).toList();
              //   },
              //   emptyBuilder: (context) {
              //     return ListTile(
              //       title: Text(
              //           'no customer found click to add ${customerNameControll.text}'),
              //       onTap: () async {
              //         customer = await Get.to(() => CustomerAdd(),
              //             arguments: customerNameControll.text);
              //         customerNameControll.text = customer?.name ?? '';
              //       },
              //     );
              //   },
              // ),
              // verSpace,
              TextFormField(
                controller: amountControll,
                decoration: inputDecoration.copyWith(
                  hintText: 'Expense Amount'.tr,
                ),
                keyboardType: TextInputType.number,
                validator: Validatorless.multiple([
                  Validatorless.required('required'.tr),
                  Validatorless.number('number'.tr),
                ]),
              ),
              verSpace,
              TextFormField(
                controller: descControll,
                decoration: inputDecoration.copyWith(
                    hintText: 'Expense description'.tr),

                maxLines: null,
                minLines: 3, // الحد الأدنى من الأسطر
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,

                // إضافة تمرير رأسي
                scrollController: ScrollController(),
                scrollPhysics: AlwaysScrollableScrollPhysics(),

                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              verSpace,
              Row(
                children: [
                  Expanded(
                    child: InputDatePickerFormField(
                      initialDate: picker,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(Duration(days: 1000)),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  horSpace,
                  IconButton(
                      onPressed: () async {
                        picker = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(Duration(days: 1000)),
                        );
                        setState(() {});
                      },
                      icon: Icon(Icons.date_range))
                ],
              ),

              verSpace,

              Expanded(child: verSpace),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate() && picker != null) {
                      databaseController.addExpense(
                        Expense(
                          description: descControll.text,
                          date: picker!,
                          amount: double.tryParse(amountControll.text) ??
                              double.parse('${amountControll.text}.0'),
                        ),
                      );
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
