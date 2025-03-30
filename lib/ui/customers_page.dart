import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/ui/customer_add.dart';
import 'package:store_management/ui/customer_view.dart';

DatabaseController databaseController = Get.find();

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

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
      ),
      body: Obx(
        () => ListView.builder(
            itemCount: databaseController.custormers().length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('customer_name'.trParams(
                    {'name': databaseController.custormers[index].name})),
                subtitle: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    Text(
                        '${'phone'.tr}: ${databaseController.custormers[index].phone}'),
                    Text(
                        '${'Invoices'.tr}: ${databaseController.custormers()[index].invoices.length}'),
                    Text(
                        '${'Transactions'.tr}: ${databaseController.custormers()[index].trasnsactions.length}'),
                  ],
                ),
                onTap: () => Get.to(
                  () => CustomerView(
                    customer: databaseController.custormers[index],
                  ),
                ),
              );
            }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => CustomerAdd());
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
              Text(settingsController.currencyFormatter(
                  databaseController.customersTransactions.fold(
                      0,
                      (previousValue, element) =>
                          previousValue + element.amount))),
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
    List<Customer> custormers = databaseController.custormers
        .where((custormer) =>
            custormer.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: custormers.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
              'Customer name: ${databaseController.custormers[index].name}'),
          subtitle: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Text(
                  '${'phone'.tr}: ${databaseController.custormers[index].phone}'),
              Text(
                  '${'Invoices'.tr}: ${databaseController.custormers()[index].invoices.length}'),
              Text(
                  '${'Transactions'.tr}: ${databaseController.custormers()[index].trasnsactions.length}'),
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
    List<Customer> custormers = databaseController.custormers
        .where((customer) =>
            customer.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: custormers.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
              'Customer name: ${databaseController.custormers[index].name}'),
          subtitle: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Text(
                  '${'phone'.tr}: ${databaseController.custormers[index].phone}'),
              Text(
                  '${'Invoices'.tr}: ${databaseController.custormers()[index].invoices.length}'),
              Text(
                  '${'Transactions'.tr}: ${databaseController.custormers()[index].trasnsactions.length}'),
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
