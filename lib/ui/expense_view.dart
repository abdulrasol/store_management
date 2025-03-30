import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/expense.dart';
import 'package:store_management/utils/app_constants.dart';

SettingsController settingsController = Get.find();

class ExpenseView extends StatelessWidget {
  const ExpenseView({super.key, required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(expense.getDate()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount'.tr),
                Text(settingsController.currencyFormatter(expense.amount))
              ],
            ),
            verSpace,
            verSpace,
            Text(expense.description),
          ],
        ),
      ),
    );
  }
}
