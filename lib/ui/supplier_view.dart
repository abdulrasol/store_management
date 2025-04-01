import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/ui/customer_edit.dart';
import 'package:store_management/ui/item_view.dart';

import '../utils/app_constants.dart';
import 'vouchers_Page.dart';

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
            // if (!GetPlatform.isLinux)
            //   IconButton(
            //     onPressed: () async {
            //       var pdf = await generateFullInvoice(customer: customer);
            //       await Share.shareXFiles([
            //         XFile.fromData(pdf)
            //       ], fileNameOverrides: [
            //         '${customer.name}-${DateTime.now()}.pdf'
            //       ]);
            //     },
            //     icon: Icon(Icons.share_outlined),
            //   ),
            // IconButton(
            //   tooltip: 'Print Customer full invoice'.tr,
            //   icon: const Icon(Icons.print),
            //   onPressed: () async {
            //     final pdf = await generateFullInvoice(customer: customer);
            //     await printPdfFileToStorage(pdf);
            //   },
            // ),
            TextButton.icon(
              onPressed: () {
                Get.to(() => CustomerEdit(
                      customer: supplier,
                    ));
              },
              label: Text('edit'.tr),
              icon: Icon(Icons.edit),
            ),
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Vouchers'.tr),
                    horSpace,
                    Icon(Icons.receipt_long)
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('items'.tr),
                    horSpace,
                    Icon(Icons.store_mall_directory)
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            voucherView(databaseController.vouchers
                .where((vou) => vou.customer.targetId == supplier.id)
                .toList()),
            ListView.builder(
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
                      Text(
                          '${'quantity'.tr}: ${supplier.items[index].quantity}'),
                      Text(
                          '${'Supplier'.tr}: ${supplier.items[index].supplier.target?.name}'),
                    ],
                  ),
                  onTap: () => Get.to(
                    () => ItemView(
                        item: databaseController.getItemById(
                            databaseController.items()[index].id)!),
                  ),
                );
              },
            )
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          //  color: Colors.purple,
          child: IconTheme(
            data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
            child: Row(
              children: <Widget>[
                Text('Customer Balance:'.tr),
                const Spacer(),
                Text(settingsController.currencyFormatter(supplier.balance())),
              ],
            ),
          ),
        ),
        //floatingActionButton: const FloatingActionButton(onPressed: null),
      ),
    );
  }
}
