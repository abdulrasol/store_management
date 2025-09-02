import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/ui/forms/customer_form.dart';
import 'package:store_management/ui/item_view.dart';

SettingsController settingsController = Get.find();
DatabaseController databaseController = Get.find();

class SupplierView extends StatelessWidget {
  const SupplierView({super.key, required this.supplier});
  final Customer supplier;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(supplier.name),
          actions: [
            TextButton.icon(
              onPressed: () {
                Get.to(() => CustomerForm(
                          customer: supplier,
                        ))!
                    .then((i) => Get.back());
              },
              label: Text('edit'.tr),
              icon: Icon(Icons.edit),
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: supplier.items.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(supplier.items[index].name),
              subtitle: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runAlignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  Text(
                      '${'Buy Price'.tr}: ${settingsController.currencyFormatter(supplier.items[index].buyPrice)}'),
                  Text(
                      '${'Sell Price'.tr}: ${settingsController.currencyFormatter(supplier.items[index].sellPrice)}'),
                  Text('${'quantity'.tr}: ${supplier.items[index].quantity}'),
                  Text(
                      '${'Supplier'.tr}: ${supplier.items[index].supplier.target?.name}'),
                ],
              ),
              onTap: () => Get.to(
                () => ItemView(
                    item: databaseController
                        .getItemById(supplier.items[index].id)!),
              ),
            );
          },
        ),
        //floatingActionButton: const FloatingActionButton(onPressed: null),
      ),
    );
  }
}
