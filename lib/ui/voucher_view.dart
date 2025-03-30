import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/voucher.dart' as d;
import 'package:store_management/utils/app_constants.dart';

class VoucherView extends StatelessWidget {
  const VoucherView({super.key, required this.voucher});
  final d.Voucher voucher;

  @override
  Widget build(BuildContext context) {
    SettingsController settingsController = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: Text('voucher: 00${voucher.voucherNumber()}'),
        leading: IconButton(
            onPressed: () {
              if (Get.previousRoute == '/VoucherSave') {
                Get.close(3);
              }
              //print(Get.previousRoute);
              Get.back();
            },
            icon: Icon(Icons.arrow_back)),
        actions: [
          IconButton(
            tooltip: 'Recover Items',
            onPressed: () async {
              // if (databaseController.re(voucher.id)) {
              //   Get.back();
              // }
              // Get.to(() => InvoiceRecoverItem(invoce: invoice));
            },
            icon: Icon(Icons.restore),
          ),
          if (!GetPlatform.isLinux)
            IconButton(
              onPressed: () async {
                // var pdf = await ge(invoice: voucher);
                // await Share.shareXFiles([
                //   XFile.fromData(pdf)
                // ], fileNameOverrides: [
                //   '${voucher.customer}-${voucher.invoiceNumber()}.pdf'
                // ]);
              },
              icon: Icon(Icons.share_outlined),
            ),
          IconButton(
              onPressed: () async {
                // var pdf = await generateInvoice(invoice: voucher);
                // Get.to(() => PrintPdfPage(pdfData: pdf));
                // final Directory? downloadsDir = await getDownloadsDirectory();
                // final Directory? dir = await getExternalStorageDirectory();
                // final String newPath =
                //     "${dir!.path}/store-management-app"; // مجلد خاص داخل مجلد التطبيق
                // final Directory newDir = Directory(newPath);

                // if (!await newDir.exists()) {
                //   await newDir.create(recursive: true);
                // }
                // final file = File("${newDir.path}/example.pdf");
                // await file.writeAsBytes(await pdf);
                //  await savePdfFileToStorage(pdf);
              },
              icon: Icon(Icons.print))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Text('Customer: ${voucher.customer.target?.name}'),
                Text(' on: ${voucher.voucherDate()}'),
                Text(' number: ${voucher.voucherNumber()}'),
              ],
            ),
            verSpace,
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Item')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Buy Price')),
                          DataColumn(label: Text('Sell Price')),
                          DataColumn(label: Text('Total Price')),
                        ],
                        rows: voucher.items
                            .map<DataRow>((item) => DataRow(
                                  cells: [
                                    DataCell(Text(item.name)),
                                    DataCell(
                                        Text(item.quantity.toStringAsFixed(0))),
                                    DataCell(Text(settingsController
                                        .currencyFormatter(item.buyPrice))),
                                    DataCell(Text(settingsController
                                        .currencyFormatter(item.sellPrice))),
                                    DataCell(Text(
                                        settingsController.currencyFormatter(
                                            item.buyPrice * item.quantity))),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(),
            Row(
              children: [
                Text('Total Amount:'),
                Expanded(child: verSpace),
                Text(settingsController.currencyFormatter(voucher.price())),
              ],
            ),
            verSpace,
            Row(
              children: [
                Text('Paid Amount:'),
                Expanded(child: verSpace),
                Text(settingsController
                    .currencyFormatter(voucher.transactions[1].amount)),
              ],
            ),
            verSpace,
            // Row(children: [
            //   Text('Amaunt to Pay:'),
            //   Expanded(child: verSpace),
            //   Text(settingsController.currencyFormatter(voucher.pricetoPay())),
            // ]),
            verSpace,
            Row(
              children: [
                Text('Supplier Balance:'),
                Expanded(child: verSpace),
                Text(settingsController.currencyFormatter(voucher.balance())),
              ],
            ),
            verSpace,
            verSpace,
            verSpace,
          ],
        ),
      ),
    );
  }
}
