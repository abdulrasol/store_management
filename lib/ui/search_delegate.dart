import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/ui/customer_view.dart';
import 'package:store_management/ui/item_view.dart';

class SearchDelegateHelper extends SearchDelegate {
  DatabaseController databaseController = Get.find();
  SettingsController settingsController = Get.find();
  List elements = [];
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
    List customers = databaseController.custormers
        .where((customer) =>
            customer.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    List suppliers = databaseController.suppliers
        .where((supplier) =>
            supplier.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    List items = databaseController.items
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    elements = [...customers, ...items, ...suppliers];
    var listView = ListView.builder(
      itemCount: elements.length,
      itemBuilder: resultBuilder,
    );
    return listView;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List customers = databaseController.custormers
        .where((customer) =>
            customer.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    List suppliers = databaseController.suppliers
        .where((supplier) =>
            supplier.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    List items = databaseController.items
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    elements = [...customers, ...items, ...suppliers];
    return ListView.builder(
      itemCount: elements.length,
      itemBuilder: resultBuilder,
    );
  }

  Widget resultBuilder(context, index) {
    if (elements[index] is Customer) {
      return ListTile(
        onTap: () => Get.to(() => CustomerView(customer: elements[index])),
        leading: Icon(elements[index].customerType == 0
            ? Icons.people
            : Icons.local_shipping),
        title: Text(elements[index].name),
        subtitle: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            if (elements[index].customerType == 0)
              Text(
                  '${'Balance'.tr}: ${settingsController.currencyFormatter(elements[index].balance())}')
          ],
        ),
      );
    } else {
      return ListTile(
        onTap: () => Get.to(() => ItemView(item: elements[index])),
        leading: Icon(Icons.shopping_bag),
        title: Text(elements[index].name),
        subtitle: Text(
            '${'Price'.tr}: ${settingsController.currencyFormatter(elements[index].sellPrice)}'),
      );
    }
  }
}
