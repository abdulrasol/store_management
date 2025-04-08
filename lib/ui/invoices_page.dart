import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/ui/invoice_view.dart';

DatabaseController databaseController = Get.find();
SettingsController settingsController = Get.find();

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoices'.tr),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(context: context, delegate: Search());
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: Obx(() => invoicesView(databaseController.inovices)),
    );
  }
}

Widget invoicesView(List<Invoice> inovices) {
  return ListView.builder(
      itemCount: inovices.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return ListTile(
            title: Text(
                '${inovices[index].customer.target!.name} - 000${inovices[index].id}'),
            subtitle: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Text(
                    '${'Price'.tr}: ${settingsController.currencyFormatter((inovices[index].pricetoPay()))}'),
                Text(
                    '${'Paid'.tr}: ${settingsController.currencyFormatter(inovices[index].transactions[0].amount)}'),
                Text(' ${inovices[index].invoiceDate()}'),
                Text(' ${inovices[index].invoiceNumber()}')
              ],
            ),
            onTap: () {
              Get.to(() => InvoiceView(invoice: inovices[index]));
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
    List<Invoice> inovices = databaseController.inovices
        .where((tra) => tra.invoiceNumber().contains(query))
        .toList();
    return ListView.builder(
        itemCount: inovices.length,
        itemBuilder: (context, index) {
          return ListTile(
              title: Text(
                  '${inovices[index].customer.target!.name} - 000${inovices[index].id}'),
              subtitle: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runAlignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  Text(
                      '${'Price'.tr}: ${settingsController.currencyFormatter(inovices[index].pricetoPay())}'),
                  Text(
                      '${'Paid'.tr}: ${settingsController.currencyFormatter(inovices[index].transactions[0].amount)}'),
                  Text(' ${inovices[index].invoiceDate()}'),
                  Text(' ${inovices[index].invoiceNumber()}')
                ],
              ),
              onTap: () {
                Get.to(() => InvoiceView(invoice: inovices[index]));
              });
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Invoice> inovices = databaseController.inovices
        .where((tra) => tra.invoiceNumber().contains(query))
        .toList();
    return ListView.builder(
        itemCount: inovices.length,
        itemBuilder: (context, index) {
          return ListTile(
              title: Text(
                  '${inovices[index].customer.target!.name} - 000${inovices[index].id}'),
              subtitle: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runAlignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  Text(
                      '${'Price'.tr}: ${settingsController.currencyFormatter(inovices[index].pricetoPay())}'),
                  Text(
                      '${'Paid'.tr}: ${settingsController.currencyFormatter(inovices[index].transactions[0].amount)}'),
                  Text(' ${inovices[index].invoiceDate()}'),
                  Text(' ${inovices[index].invoiceNumber()}')
                ],
              ),
              onTap: () {
                Get.to(() => InvoiceView(invoice: inovices[index]));
              });
        });
  }
}
