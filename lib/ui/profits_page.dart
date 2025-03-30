import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/ui/invoices_page.dart';

import '../controllers/settings_controller.dart';

SettingsController settingsController = Get.find();

class ProfitsPage extends StatelessWidget {
  const ProfitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Profits'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Obx(
          () => ListView.builder(
            itemCount: databaseController.profits.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                    'Profit Amount :${settingsController.currencyFormatter(databaseController.profits[index].profit())}'),
                subtitle: Column(
                  // alignment: WrapAlignment.spaceBetween,
                  //runAlignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Total Invoice Price: ${settingsController.currencyFormatter(databaseController.profits[index].invoice.target!.pricetoPay())}'),
                    Text(
                        'Customer: ${databaseController.profits[index].invoice.target!.customer.target!.name}'),
                    Text(
                        'Invoice Date: ${databaseController.profits[index].invoice.target!.invoiceDate()}'),
                    Text(
                        'Invoice Number: ${databaseController.profits[index].invoice.target!.invoiceNumber()}'),
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
              Text('Total Profits:'),
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
