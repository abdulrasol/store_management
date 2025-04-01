import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/item.dart';

import 'package:store_management/ui/item_edit.dart';

class ItemView extends StatelessWidget {
  const ItemView({super.key, required this.item});
  final Item item;

  @override
  Widget build(BuildContext context) {
    SettingsController settingsController = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          TextButton.icon(
            onPressed: () {
              Get.to(() => EditItem(itemModel: item));
            },
            icon: Icon(Icons.edit),
            label: Text('edit'.tr),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text(item.name),
              subtitle: Text('Item Name'.tr),
            ),
            ListTile(
              title: Text(item.code()),
              subtitle: Text('item code'.tr),
            ),
            ListTile(
              title: Text(settingsController.currencyFormatter(item.buyPrice)),
              subtitle: Text('Buy Price'.tr),
            ),
            ListTile(
              title: Text(settingsController.currencyFormatter(item.sellPrice)),
              subtitle: Text('Sell Price'.tr),
            ),
            ListTile(
              title: Text(
                  item.availabllty() ? 'available'.tr : 'not available'.tr),
              subtitle: Text('${item.quantity} ${'available'.tr}'),
            ),
            ListTile(
              title: Text('Supplier'.tr),
              subtitle: Text('${item.supplier.target?.name} '),
            ),
          ],
        ),
      ),
    );
  }
}
