import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/ui/forms/customer_form.dart';
import 'package:store_management/ui/customer_view.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:store_management/controllers/settings_controller.dart';

DatabaseController databaseController = Get.find();
SettingsController settingsController = Get.find();

class CustomersPageController extends GetxController {
  final _filterType = 0.obs; // 0: All, 1: Debtors
  int get filterType => _filterType.value;
  set filterType(int value) => _filterType.value = value;

  List<Customer> get filteredCustomers {
    if (filterType == 1) {
      return databaseController.custormers.where((c) => c.balance() < 0).toList();
    }
    return databaseController.custormers;
  }
}

class CustomersPage extends StatelessWidget {
  CustomersPage({super.key});
  final controller = Get.put(CustomersPageController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('customers'.tr),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(context: context, delegate: Search());
            },
            icon: Icon(Icons.search),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Obx(
            () => Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All'.tr),
                    selected: controller.filterType == 0,
                    onSelected: (bool selected) {
                      controller.filterType = 0;
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Debts'.tr),
                    selected: controller.filterType == 1,
                    onSelected: (bool selected) {
                      controller.filterType = 1;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        final customers = controller.filteredCustomers;
        if (customers.isEmpty) {
          return Center(child: Text('No data available'.tr));
        }
        return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return ListTile(
                title: Text('customer_name'.trParams({'name': customer.name})),
                subtitle: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    Text('${'phone'.tr}: ${customer.phone}'),
                    Text('${'Invoices'.tr}: ${customer.invoices.length}'),
                    Text('${'Transactions'.tr}: ${customer.trasnsactions.length}'),
                    if (customer.balance() < 0)
                      Text(
                        '${'Balance'.tr}: ${settingsController.currencyFormatter(customer.balance())}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.message, color: Colors.green),
                  onPressed: () async {
                    String phone = customer.phone;
                    if (phone.isNotEmpty) {
                      // Basic cleanup
                      phone = phone.replaceAll(RegExp(r'[^\d+]'), '');

                      // Explicitly try whatsapp:// scheme first if possible, or robust universal link
                      // Universal link is standard: https://wa.me/$phone
                      final Uri universalLink = Uri.parse('https://wa.me/$phone');
                      final Uri schemeLink = Uri.parse('whatsapp://send?phone=$phone');

                      if (await canLaunchUrl(universalLink)) {
                        await launchUrl(universalLink, mode: LaunchMode.externalApplication);
                      } else if (await canLaunchUrl(schemeLink)) {
                        await launchUrl(schemeLink);
                      } else {
                        Get.snackbar('Error', 'Could not launch WhatsApp for $phone');
                      }
                    } else {
                      Get.snackbar('Error', 'No phone number for this customer');
                    }
                  },
                ),
                onTap: () => Get.to(
                  () => CustomerView(
                    customer: customer,
                  ),
                ),
              );
            });
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => CustomerForm());
        },
        label: Text('Add'.tr),
        icon: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        //  color: Colors.purple,
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(
            children: <Widget>[
              Text('Total Unpaid Amounts'.tr),
              const Spacer(),
              Text(settingsController
                  .currencyFormatter(databaseController.customersTransactions.fold(0, (previousValue, element) => previousValue + element.amount))),
            ],
          ),
        ),
      ),
    );
  }
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
    List<Customer> custormers = databaseController.custormers.where((custormer) => custormer.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: custormers.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Customer name: ${databaseController.custormers[index].name}'),
          subtitle: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Text('${'phone'.tr}: ${databaseController.custormers[index].phone}'),
              Text('${'Invoices'.tr}: ${databaseController.custormers()[index].invoices.length}'),
              Text('${'Transactions'.tr}: ${databaseController.custormers()[index].trasnsactions.length}'),
            ],
          ),
          onTap: () => Get.to(
            () => CustomerView(
              customer: databaseController.custormers[index],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Customer> custormers = databaseController.custormers.where((customer) => customer.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: custormers.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Customer name: ${databaseController.custormers[index].name}'),
          subtitle: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Text('${'phone'.tr}: ${databaseController.custormers[index].phone}'),
              Text('${'Invoices'.tr}: ${databaseController.custormers()[index].invoices.length}'),
              Text('${'Transactions'.tr}: ${databaseController.custormers()[index].trasnsactions.length}'),
            ],
          ),
          onTap: () => Get.to(
            () => CustomerView(
              customer: databaseController.custormers[index],
            ),
          ),
        );
      },
    );
  }
}
