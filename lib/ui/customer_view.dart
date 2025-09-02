import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/ui/forms/customer_form.dart';
import 'package:store_management/ui/transaction_add.dart';
import 'package:store_management/utils/printing/customer_full_invoice_pdf.dart';
import 'package:store_management/utils/printing/save_pdf.dart';

import '../utils/app_constants.dart';
import 'invoices_page.dart';
import 'transactions_page.dart';

SettingsController settingsController = Get.find();

class CustomerView extends StatelessWidget {
  const CustomerView({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(customer.name),
          actions: [
            if (!GetPlatform.isLinux)
              IconButton(
                onPressed: () async {
                  var pdf = await generateFullInvoice(customer: customer);
                  await Share.shareXFiles([
                    XFile.fromData(pdf)
                  ], fileNameOverrides: [
                    '${customer.name}-${DateTime.now()}.pdf'
                  ]);
                },
                icon: Icon(Icons.share_outlined),
              ),
            IconButton(
              tooltip: 'Print Customer full invoice'.tr,
              icon: const Icon(Icons.print),
              onPressed: () async {
                final pdf = await generateFullInvoice(customer: customer);
                await printPdfFileToStorage(pdf);
              },
            ),
            TextButton.icon(
              onPressed: () {
                Get.to(() => CustomerForm(
                      update: true,
                      customer: customer,
                    ))?.then((i) => Get.back());
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
                    Text('Invoices'.tr),
                    horSpace,
                    Icon(Icons.receipt_long)
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Transactions'.tr),
                    horSpace,
                    Icon(Icons.payment_sharp)
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            invoicesView(customer.invoices),
            transactionsView(customer.trasnsactions),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Get.to(() => TransactionAdd(customer: customer));
          },
          child: Icon(Icons.payment),
        ),
        bottomNavigationBar: BottomAppBar(
          //  color: Colors.purple,
          child: IconTheme(
            data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
            child: Row(
              children: <Widget>[
                Text('Customer Balance:'.tr),
                const Spacer(),
                Text(settingsController.currencyFormatter(customer.balance())),
              ],
            ),
          ),
        ),
        //floatingActionButton: const FloatingActionButton(onPressed: null),
      ),
    );
  }
}
