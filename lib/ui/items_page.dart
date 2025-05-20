import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/item.dart';
import 'package:store_management/ui/voucher_create.dart';
import 'package:store_management/ui/item_view.dart';

DatabaseController databaseController = Get.find();
SettingsController settingsController = Get.find();

class ItemsPage extends StatelessWidget {
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('items'.tr),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                  context: context,
                  delegate: Search(),
                  useRootNavigator: true,
                  maintainState: true);
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: Obx(
        () => ListView.builder(
            itemCount: databaseController.items().length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(databaseController.items()[index].name),
                subtitle: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    Text(
                        '${'Buy Price'.tr}: ${settingsController.currencyFormatter(databaseController.items()[index].buyPrice)}'),
                    Text(
                        '${'Sell Price'.tr}: ${settingsController.currencyFormatter(databaseController.items()[index].sellPrice)}'),
                    Text(
                        '${'quantity'.tr}: ${databaseController.items()[index].quantity}'),
                    Text(
                        '${'Supplier'.tr}: ${databaseController.items()[index].supplier.target?.name}'),
                  ],
                ),
                onTap: () => Get.to(
                  () => ItemView(
                      item: databaseController
                          .getItemById(databaseController.items()[index].id)!),
                ),
              );
            }),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            Get.to(() => VoucherCreate());
          },
          child: Icon(Icons.add)),
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
    List<Item> items = databaseController.items
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index].name),
          subtitle: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Text(
                  '${'Buy Price'.tr}: ${settingsController.currencyFormatter(items[index].buyPrice)}'),
              Text(
                  '${'Sell Price'.tr}: ${settingsController.currencyFormatter(items[index].sellPrice)}'),
              Text(
                  '${'quantity'.tr}: ${items[index].quantity}'),
              Text(
                  '${'Supplier'.tr}: ${items[index].supplier.target?.name}'),
            ],
          ),
          onTap: () => Get.to(
            () => ItemView(
                item: databaseController.getItemById(items[index].id)!),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Item> items = databaseController.items
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index].name),
          subtitle: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Text(
                  '${'Buy Price'.tr}: ${settingsController.currencyFormatter(items[index].buyPrice)}'),
              Text(
                  '${'Sell Price'.tr}: ${settingsController.currencyFormatter(items[index].sellPrice)}'),
              Text(
                  '${'quantity'.tr}: ${items[index].quantity}'),
              Text(
                  '${'Supplier'.tr}: ${items[index].supplier.target?.name}'),
            ],
          ),
          onTap: () => Get.to(
            () => ItemView(
                item: databaseController
                    .getItemById(items[index].id)!),
          ),
        );
      },
    );
  }
}
