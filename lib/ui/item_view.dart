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
            label: Text('edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text(item.name),
              subtitle: Text('item name'),
            ),
            ListTile(
              title: Text(item.code()),
              subtitle: Text('item code'),
            ),
            // ListTile(
            //   title: Text(item.from),
            //   subtitle: Text('item buy from'),
            // ),
            ListTile(
              title: Text(settingsController.currencyFormatter(item.buyPrice)),
              subtitle: Text('item buy price'),
            ),
            ListTile(
              title: Text(settingsController.currencyFormatter(item.sellPrice)),
              subtitle: Text('item sell price'),
            ),
            ListTile(
              title: Text(item.availabllty() ? 'available' : 'not available'),
              subtitle: Text('${item.quantity} left'),
            ),
            ListTile(
              title: Text('Subllier'),
              subtitle: Text('${item.supplier.target?.name} '),
            ),
          ],
        ),
      ),
    );
  }
}
