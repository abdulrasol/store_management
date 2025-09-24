import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/ui/invoice_view.dart';
import 'package:store_management/ui/invoices_page.dart';

import '../controllers/settings_controller.dart';

SettingsController settingsController = Get.find();

class ProfitsPage extends StatelessWidget {
  const ProfitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profits'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Obx(
          () => ListView.builder(
            itemCount: databaseController.profits.length,
            itemBuilder: (context, index) {
              return ListTile(
                onTap: () => Get.to(() => InvoiceView(
                    invoice:
                        databaseController.profits[index].invoice.target!)),
                title: Text(
                    '${'Profit Amount'.tr} :${settingsController.currencyFormatter(databaseController.profits[index].profit())}'),
                subtitle: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    Text(
                        '${'Total Price'.tr}: ${settingsController.currencyFormatter(databaseController.profits[index].invoice.target!.pricetoPay())}'),
                    Text(
                        '${'custormer name'.tr}: ${databaseController.profits[index].invoice.target!.customer.target!.name}'),
                    Text(
                        '${'Invoice Date'.tr}: ${databaseController.profits[index].invoice.target!.invoiceDate()}'),
                    Text(
                        '${'Invoice Number'.tr}: ${databaseController.profits[index].invoice.target!.invoiceNumber()}'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        //  color: Colors.purple,
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(
            children: <Widget>[
              Text('Total Profits'.tr),
              const Spacer(),
              Text(settingsController.currencyFormatter(
                  databaseController.profits.fold(
                      0,
                      (previousValue, element) =>
                          previousValue + element.profit()))),
            ],
          ),
        ),
      ),
    );
  }
}
