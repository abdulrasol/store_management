import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:store_management/utils/printing/save_pdf.dart';
import 'package:store_management/utils/printing/transaction_pdf.dart';

class TransactionView extends StatelessWidget {
  const TransactionView({super.key, required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    SettingsController settingsController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: Text('${transaction.customer.target?.name}'),
        actions: [
          if (!GetPlatform.isDesktop)
            IconButton(
              onPressed: () async {
                {
                  final pdf =
                      await generateTransaction(transaction: transaction);
                  await Share.shareXFiles([
                    XFile.fromData(pdf)
                  ], fileNameOverrides: [
                    '${transaction.customer.target!.name}-${transaction.transactionNumber()}.pdf'
                  ]);
                }
              },
              icon: Icon(Icons.share_outlined),
            ),
          IconButton(
              onPressed: () async {
                final pdf = await generateTransaction(transaction: transaction);
                await printPdfFileToStorage(pdf);
              },
              icon: Icon(Icons.print))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            verSpace,
            Row(
              children: [
                Text('Transaction Date'.tr),
                Expanded(child: verSpace),
                Text(transaction.paymentDate())
              ],
            ),
            verSpace,
            Row(
              children: [
                Text('Transaction Type'.tr),
                Expanded(child: verSpace),
                Text(transaction.stringType())
              ],
            ),
            verSpace,
            Row(
              children: [
                Text('Amount'.tr),
                Expanded(child: verSpace),
                Text(settingsController.currencyFormatter(transaction.amount))
              ],
            ),
            verSpace,
            Row(
              children: [
                Text('Customer Balance:'.tr),
                Expanded(child: verSpace),
                Text(settingsController
                    .currencyFormatter(transaction.customer.target!.balance()))
              ],
            ),
            verSpace,
          ],
        ),
      ),
    );
  }
}
