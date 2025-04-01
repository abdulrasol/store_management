import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/voucher.dart';
import 'package:store_management/ui/voucher_view.dart';

DatabaseController databaseController = Get.find();
SettingsController settingsController = Get.find();

class VouchersPage extends StatelessWidget {
  const VouchersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vouchers'.tr),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(context: context, delegate: Search());
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: Obx(() => voucherView(databaseController.vouchers)),
    );
  }
}

Widget voucherView(List<Voucher> voucher) {
  return ListView.builder(
      itemCount: voucher.length,
      itemBuilder: (context, index) {
        return ListTile(
            title: Text(
                '${voucher[index].customer.target!.name} - 000${voucher[index].id}'),
            subtitle: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Text(
                    '${'Price'.tr}: ${settingsController.currencyFormatter((voucher[index].price()))}'),
                Text(
                    '${'Paid'.tr}: ${settingsController.currencyFormatter(voucher[index].transactions[0].amount)}'),
                Text(' ${voucher[index].voucherDate()}'),
                Text(' ${voucher[index].voucherNumber()}')
              ],
            ),
            onTap: () {
              Get.to(() => VoucherView(voucher: voucher[index]));
            });
      });
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
    List<Voucher> vouchers = databaseController.vouchers
        .where((tra) => tra.voucherNumber().contains(query))
        .toList();
    return searchResultBuilder(vouchers);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Voucher> vouchers = databaseController.vouchers
        .where((tra) => tra.voucherNumber().contains(query))
        .toList();
    return searchResultBuilder(vouchers);
  }

  ListView searchResultBuilder(List<Voucher> vouchers) {
    return ListView.builder(
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          return ListTile(
              title: Text(
                  '${vouchers[index].customer.target!.name} - 000${vouchers[index].id}'),
              subtitle: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runAlignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  Text(
                      '${'Price'.tr}: ${settingsController.currencyFormatter((vouchers[index].price()))}'),
                  Text(
                      '${'Paid'.tr}: ${settingsController.currencyFormatter(vouchers[index].transactions[0].amount)}'),
                  Text(' ${vouchers[index].voucherDate()}'),
                  Text(' ${vouchers[index].voucherNumber()}')
                ],
              ),
              onTap: () {
                Get.to(() => VoucherView(voucher: vouchers[index]));
              });
        });
  }
}
