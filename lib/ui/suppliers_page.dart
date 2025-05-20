import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/ui/customer_view.dart';
import 'package:store_management/ui/supplier_add.dart';
import 'package:store_management/ui/supplier_view.dart';

DatabaseController databaseController = Get.find();

class SupplierPage extends StatelessWidget {
  const SupplierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suppliers'.tr),
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
            itemCount: databaseController.suppliers().length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(databaseController.suppliers[index].name),
                subtitle: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    Text(
                        '${'phone'.tr}: ${databaseController.suppliers[index].phone}'),
                    Text(
                        '${'items'.tr}: ${databaseController.suppliers()[index].items.length}'),
                  ],
                ),
                onTap: () => Get.to(
                  () => SupplierView(
                    supplier: databaseController.suppliers[index],
                  ),
                ),
              );
            }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => SupplierAdd());
        },
        icon: Icon(Icons.add),
        label: Text('Add'.tr),
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
    List<Customer> suppliers = databaseController.suppliers
        .where((custormer) =>
            custormer.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return resuiltBuilder(suppliers);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Customer> suppliers = databaseController.suppliers
        .where((customer) =>
            customer.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return resuiltBuilder(suppliers);
  }

  ListView resuiltBuilder(List<Customer> suppliers) {
    return ListView.builder(
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        return ListTile(
          title:
              Text('${'name'.tr}: ${databaseController.suppliers[index].name}'),
          subtitle: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Text(
                  '${'phone'.tr}: ${databaseController.suppliers[index].phone}'),
              Text(
                  '${'Invoices'.tr}: ${databaseController.suppliers()[index].invoices.length}'),
              Text(
                  '${'Transactions'.tr}: ${databaseController.suppliers()[index].trasnsactions.length}'),
            ],
          ),
          onTap: () => Get.to(
            () => SupplierView(
              supplier: databaseController.suppliers[index],
            ),
          ),
        );
      },
    );
  }
}
