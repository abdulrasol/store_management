import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/models/expense.dart';
import 'package:store_management/ui/expense_add.dart';
import 'package:store_management/ui/expense_view.dart';
import 'package:store_management/ui/invoices_page.dart';
import 'package:store_management/utils/app_constants.dart';

import '../controllers/settings_controller.dart';

SettingsController settingsController = Get.find();

int currentMounthMilliSecond =
    DateTime(DateTime.now().year, DateTime.now().month, 1)
        .millisecondsSinceEpoch;
int currentyearMilliSecond =
    DateTime(DateTime.now().year, 1, 1).millisecondsSinceEpoch;
int all = DateTime(2024, 1, 1).millisecondsSinceEpoch;
int viewExpenseFrom = all;

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses'.tr),
        actions: [
          IconButton(
              onPressed: () {
                showSearch(context: context, delegate: Search());
              },
              icon: Icon(Icons.search))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DropdownButton<int>(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                //  isDense: true,
                isExpanded: true,
                icon: const Icon(Icons.date_range),
                //elevation: 16,
                // style: const TextStyle(color: Colors.deepPurple),
                // underline: Container(height: 2, color: Colors.deepPurpleAccent),
                value: viewExpenseFrom,
                items: [
                  DropdownMenuItem<int>(
                    value: all,
                    child: Text('All'.tr),
                  ),
                  DropdownMenuItem<int>(
                    value: currentMounthMilliSecond,
                    child: Text('This Mounth'.tr),
                  ),
                  DropdownMenuItem<int>(
                    value: currentyearMilliSecond,
                    child: Text('This Year'.tr),
                  )
                ],
                onChanged: (value) {
                  setState(() {
                    viewExpenseFrom = value!;
                  });
                }),
            ListView.builder(
              shrinkWrap: true,
              itemCount: databaseController.expenses
                  .where((expense) =>
                      expense.date.millisecondsSinceEpoch >= viewExpenseFrom)
                  .toList()
                  .length,
              itemBuilder: (context, index) {
                return ListTile(
                  // onTap: () => Get.to(() => ExpenseView(
                  //     expense: databaseController.expenses
                  //         .where((expense) =>
                  //             expense.date.millisecondsSinceEpoch >=
                  //             viewExpenseFrom)
                  //         .toList()[index])),
                  title: Text(
                      '${'Amount'.tr} :${settingsController.currencyFormatter(databaseController.expenses[index].amount)}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          // minHeight: 0.0,
                          maxHeight: 50.0,
                        ),
                        child: Text(
                          databaseController.expenses
                              .where((expense) =>
                                  expense.date.millisecondsSinceEpoch >=
                                  viewExpenseFrom)
                              .toList()[index]
                              .description,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                      Text(databaseController.expenses
                          .where((expense) =>
                              expense.date.millisecondsSinceEpoch >=
                              viewExpenseFrom)
                          .toList()[index]
                          .getDate()),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => ExpenseAdd());
        },
        label: Text('New Expense'.tr),
        icon: Icon(Icons.attach_money_outlined),
      ),
      bottomNavigationBar: BottomAppBar(
        //  color: Colors.purple,
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(
            children: <Widget>[
              Text('Total Expenses'.tr),
              const Spacer(),
              Text(settingsController.currencyFormatter(databaseController
                  .expenses
                  .where((expense) =>
                      expense.date.millisecondsSinceEpoch >= viewExpenseFrom)
                  .toList()
                  .fold(
                      0,
                      (previousValue, element) =>
                          previousValue + element.amount))),
            ],
          ),
        ),
      ),
    );
  }

  /// disappear
}

class Search extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Expense> expenses = databaseController.expenses
        .where((tra) => tra.description.contains(query))
        .toList();
    return ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
                settingsController.currencyFormatter(expenses[index].amount)),
            subtitle: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Text(expenses[index].description),
                horSpace,
                Text(expenses[index].getDate()),
                // Text(' ${databaseController.inovices[index].invoiceDate()}')
              ],
            ),
            onTap: () {
              Get.to(() => ExpenseView(expense: expenses[index]));
            },
          );
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Expense> expenses = databaseController.expenses
        .where((tra) => tra.description.contains(query))
        .toList();
    return ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
                settingsController.currencyFormatter(expenses[index].amount)),
            subtitle: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Text(expenses[index].description),
                horSpace,
                Text(expenses[index].getDate()),
                // Text(' ${databaseController.inovices[index].invoiceDate()}')
              ],
            ),
            onTap: () {
              Get.to(() => ExpenseView(expense: expenses[index]));
            },
          );
        });
  }
}
