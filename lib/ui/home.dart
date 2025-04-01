import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_speed_dial/simple_speed_dial.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/queries.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/ui/expense_add.dart';
import 'package:store_management/ui/expenses_page.dart';
import 'package:store_management/ui/store_settings.dart';
import 'package:store_management/ui/customers_page.dart';
import 'package:store_management/ui/invoice_create.dart';
import 'package:store_management/ui/items_page.dart';
import 'package:store_management/ui/cards/home_card.dart';
import 'package:store_management/ui/profits_page.dart';
import 'package:store_management/ui/search_delegate.dart';
import 'package:store_management/ui/suppliers_page.dart';
import 'package:store_management/ui/transaction_add.dart';
import 'package:store_management/ui/transactions_page.dart';
import 'package:store_management/ui/vouchers_Page.dart';
import 'package:store_management/utils/app_constants.dart';
import 'invoices_page.dart';

DatabaseController databaseController = Get.find(); //put(DatabaseController());
SettingsController settingsController = Get.find();

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Queries queries = Queries();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          settingsController.appName.value ?? 'Sales Management App'.tr,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(context: context, delegate: SearchDelegateHelper());
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          //crossAxisAlignment: Cr,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceAround,
              runAlignment: WrapAlignment.spaceAround,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                HomeCard(
                  width: (MediaQuery.sizeOf(context).width) - 30,
                  color: Colors.teal,
                  count: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Sales'.tr),
                          Obx(
                            () => Text(
                              settingsController.currencyFormatter(
                                databaseController.inovices.fold(
                                  0,
                                  (num previousValue, element) =>
                                      previousValue + element.pricetoPay(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      verSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Last Month Sales'.tr),
                          Obx(
                            () => Text(
                              settingsController.currencyFormatter(
                                databaseController.inovices
                                    .where((invoice) =>
                                        invoice.date >
                                        DateTime.now().millisecondsSinceEpoch -
                                            2629800000)
                                    .toList()
                                    .fold(
                                      0,
                                      (num previousValue, element) =>
                                          previousValue + element.pricetoPay(),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                HomeCard(
                  width: (MediaQuery.sizeOf(context).width) - 30,
                  color: Colors.deepPurpleAccent,
                  count: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Paid-up capital'.tr),
                          Obx(
                            () => Text(
                              settingsController.currencyFormatter(
                                (-1 *
                                        databaseController.supplierTransactions
                                            .where((tran) => tran.amount < 0)
                                            .toList()
                                            .fold(
                                                0,
                                                (previousValue, element) =>
                                                    previousValue +
                                                    element.amount)) +
                                    (databaseController.expenses.fold(
                                        0,
                                        (previousValue, element) =>
                                            previousValue + element.amount)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      verSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Expense'.tr),
                          Obx(() => Text(settingsController.currencyFormatter(
                              databaseController.expenses.fold(
                                  0,
                                  (previousValue, element) =>
                                      previousValue + element.amount)))),
                        ],
                      ),
                      verSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Net revenue'.tr),
                          Obx(
                            () => Text(settingsController.currencyFormatter(
                                databaseController.netRevenue())),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                HomeCard(
                  width: (MediaQuery.sizeOf(context).width) - 30,
                  color: Colors.pink,
                  count: 5,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Available Items Count'.tr),
                          Obx(() => Text(databaseController.items
                              .where((item) => item.quantity > 0)
                              .toList()
                              .length
                              .toString())),
                        ],
                      ),
                      verSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Not Available Items Count'.tr),
                          Obx(() => Text(databaseController.items
                              .where((item) => item.quantity <= 0)
                              .toList()
                              .length
                              .toString())),
                        ],
                      ),
                      verSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Items less 5 in stocks'.tr),
                          Obx(() => Text(databaseController.items
                              .where((item) => item.quantity < 10)
                              .toList()
                              .length
                              .toString())),
                        ],
                      ),
                    ],
                  ),
                ),
                HomeCard(
                  width: (MediaQuery.sizeOf(context).width) - 30,
                  color: Colors.green,
                  count: 5,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount of Outstanding Debt'.tr),
                          Obx(() => Text(settingsController.currencyFormatter(
                              databaseController.customerDebt()))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            verSpace,
            Divider(),
            verSpace,
            Row(
              children: [
                Text(
                  'Last Invoices'.tr,
                  style: TextStyle(fontSize: 16),
                )
              ],
            ),
            Expanded(
              flex: 1,
              child: Obx(
                () => invoicesView(
                  databaseController.inovices
                      .getRange(
                          0,
                          databaseController.inovices.length > 10
                              ? 10
                              : databaseController.inovices.length)
                      .toList(),
                ),
              ),
            ),
            Divider(),
            verSpace,
            Row(
              children: [
                Text(
                  'Last Payments'.tr,
                  style: TextStyle(fontSize: 16),
                )
              ],
            ),
            Expanded(
              flex: 1,
              child: Obx(() => transactionsView(
                    databaseController.customersTransactions
                        .getRange(
                            0,
                            databaseController.customersTransactions.length > 10
                                ? 10
                                : databaseController
                                    .customersTransactions.length)
                        .toList(),
                  )),
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        speedDialChildren: <SpeedDialChild>[
          SpeedDialChild(
            child: Icon(Icons.receipt_long),
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
            label: 'Create Invoice'.tr,
            onPressed: () {
              Get.to(() => InvoiceCreate());
            },
            closeSpeedDialOnPressed: true,
          ),
          SpeedDialChild(
            child: Icon(Icons.payment),
            foregroundColor: Colors.white,
            backgroundColor: Colors.lightBlue,
            label: 'New Transactions'.tr,
            onPressed: () {
              Get.to(() => TransactionAdd());
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.attach_money_outlined),
            foregroundColor: Colors.white,
            backgroundColor: Colors.orange,
            label: 'New Expense'.tr,
            onPressed: () {
              Get.to(() => ExpenseAdd());
            },
          ),
        ],
        closedForegroundColor: Colors.white,
        openForegroundColor: Colors.white,
        closedBackgroundColor: Colors.green.shade700,
        openBackgroundColor: Colors.black,
        labelsBackgroundColor: Get.theme.secondaryHeaderColor,
        child: const Icon(Icons.add),
      ),
      drawer: Drawer(
        //backgroundColor: appTheme.primaryColor,
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              // decoration: BoxDecoration(color: Colors.teal),
              child: Column(
                children: [
                  settingsController.logo.value != null
                      ? SizedBox(
                          width: 120,
                          height: 120,
                          child: Image.memory(
                            base64Decode(settingsController.logo.value!),
                            fit: BoxFit.contain,
                          ),
                        )
                      : Icon(
                          Icons.point_of_sale_outlined,
                          size: 80,
                          color: Colors.blue.shade700,
                        )
                ],
              ),
            ),
            ListTile(
              onTap: () {
                Get.to(() => ItemsPage());
              },
              title: Text('items'.tr),
              leading: Icon(Icons.store),
              // subtitle: Text('view and manage items'.tr),
            ),
            ListTile(
              onTap: () {
                Get.to(() => InvoicesPage());
              },
              title: Text('Invoices'.tr),
              leading: Icon(Icons.receipt),
              //  subtitle: Text('view and manage invoice'.tr),
            ),
            ListTile(
              onTap: () {
                Get.to(() => TransactionsPage());
              },
              title: Text('Transactions'.tr),
              leading: Icon(Icons.payments),
              //subtitle: Text('view and manage payment'.tr),
            ),
            ListTile(
              onTap: () {
                Get.to(() => ExpensesPage());
              },
              title: Text('Expenses'.tr),
              leading: Icon(Icons.attach_money_outlined),
              // subtitle: Text('All Store Expenses'.tr),
            ),
            ListTile(
              onTap: () {
                Get.to(() => CustomersPage());
              },
              title: Text('customers'.tr),
              leading: Icon(Icons.people),
              // subtitle: Text('view and manage customers'.tr),
            ),
            ListTile(
              onTap: () {
                Get.to(() => ProfitsPage());
              },
              title: Text('Profits'.tr),
              leading: Icon(Icons.currency_bitcoin),
              // subtitle: Text('view your profits'.tr),
            ),
            ListTile(
              onTap: () {
                Get.to(() => SupplierPage());
              },
              title: Text('Suppliers'.tr),
              leading: Icon(Icons.support),
              // subtitle: Text('Trade Suppliers'.tr),
            ),
            ListTile(
              onTap: () {
                Get.to(() => VouchersPage());
              },
              title: Text('Vouchers'.tr),
              leading: Icon(Icons.receipt_long),
              //  subtitle: Text('Trade Suppliers'.tr),
            ),
            Divider(),
            ListTile(
              onTap: () {
                Get.to(() => StoreSettings());
              },
              title: Text('Edit Store Information'.tr),
              leading: Icon(Icons.settings),

              // subtitle: Text('view and edit store information'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
