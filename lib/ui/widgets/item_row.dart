import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/item.dart';

class ItemRow extends StatelessWidget {
  const ItemRow({
    super.key,
    required this.item,
  });

  final Item item;

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.find();
    return ListTile(
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
              child: Text(
                '${'Sell Price'.tr}: ${settingsController.currencyFormatter(item.sellPrice)}',
                style: TextStyle(color: Colors.green),
              ),
            ),
            Flexible(
              child: Text(
                '${'Buy Price'.tr}: ${settingsController.currencyFormatter(item.buyPrice)} ',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ]),
          Text(
            '${item.quantity} ${'available'.tr}',
            style: TextStyle(color: Colors.grey),
          ),
          Divider(),
        ],
      ),
    );
  }
}
