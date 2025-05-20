import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/ui/customers_page.dart';
import 'package:store_management/ui/expenses_page.dart';
import 'package:store_management/ui/invoice_create.dart';
import 'package:store_management/ui/invoice_view.dart';
import 'package:store_management/ui/invoices_page.dart';
import 'package:store_management/ui/items_page.dart';
import 'package:store_management/ui/profits_page.dart';
import 'package:store_management/ui/search_delegate.dart';
import 'package:store_management/ui/store_settings.dart';
import 'package:store_management/ui/suppliers_page.dart';

class Home extends StatelessWidget {
  Home({super.key});

  final databaseController = Get.find<DatabaseController>();
  final settingsController = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          settingsController.appName.value ?? 'Sales Management App'.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: SearchDelegateHelper());
            },
          )
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async {
          // await databaseController.loadData(); // فرضًا عندك هيج ميثود
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryCards(context),
              const SizedBox(height: 24),
              _buildRecentInvoices(context),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width / 2 - 24;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _statCard(
          onTap: () => Get.to(() => InvoicesPage()),
          title: 'Total Sales'.tr,
          icon: Icons.attach_money,
          color: Colors.teal,
          value: Obx(
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
          width: cardWidth,
        ),
        _statCard(
          onTap: () => Get.to(() => ProfitsPage()),
          title: 'Net revenue'.tr,
          icon: Icons.bar_chart,
          color: Colors.deepPurple,
          value: Obx(() => Text(settingsController
              .currencyFormatter(databaseController.netRevenue()))),
          width: cardWidth,
        ),
        _statCard(
          title: 'Available Items Count'.tr,
          icon: Icons.inventory_2,
          color: Colors.green,
          value: Obx(() => Text(databaseController.items
              .where((item) => item.quantity > 0)
              .length
              .toString())),
          width: cardWidth,
        ),
        _statCard(
          title: 'Total Amount of Outstanding Debt'.tr,
          icon: Icons.money_off_csred,
          color: Colors.redAccent,
          value: Obx(() => Text(settingsController
              .currencyFormatter(databaseController.customerDebt()))),
          width: cardWidth,
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget value,
    required double width,
    void Function()? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            value,
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last Invoices'.tr, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Obx(
          () => ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: databaseController.inovices.length > 5
                ? 5
                : databaseController.inovices.length,
            itemBuilder: (context, index) {
              var invoice = databaseController.inovices[index];
              return Card(
                child: ListTile(
                  onTap: () => Get.to(() => InvoiceView(invoice: invoice)),
                  title: Text(invoice.customer.target!.name),
                  subtitle: Text(
                      'Total: ${settingsController.currencyFormatter(invoice.pricetoPay())}'),
                  trailing: Text(invoice.invoiceDate()),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDial() {
    return FloatingActionButton(
      onPressed: () {
        Get.to(() => InvoiceCreate());
      },
      backgroundColor: Colors.green.shade700,
      child: const Icon(Icons.add),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Center(
              child: settingsController.logo.value != null
                  ? Image.memory(
                      base64Decode(settingsController.logo.value!),
                      fit: BoxFit.contain,
                    )
                  : Icon(Icons.storefront, size: 80, color: Colors.teal),
            ),
          ),
          _drawerItem('items'.tr, Icons.shopping_bag, () {
            Get.to(() => ItemsPage());
          }),
          _drawerItem('customers'.tr, Icons.people, () {
            Get.to(() => CustomersPage());
          }),
          _drawerItem('Suppliers'.tr, Icons.local_shipping, () {
            Get.to(() => SupplierPage());
          }),
          _drawerItem('Expenses'.tr, Icons.money, () {
            Get.to(() => ExpensesPage());
          }),
          _drawerItem('App Settings'.tr, Icons.settings, () {
            Get.to(() => StoreSettings());
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title.tr),
      onTap: onTap,
    );
  }
}
