import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/item.dart';
import 'package:store_management/utils/app_constants.dart';

class VoucherView extends StatelessWidget {
  const VoucherView({super.key, required this.newItems});
  final List<Item> newItems;

  @override
  Widget build(BuildContext context) {
    SettingsController settingsController = Get.find();
    return Scaffold(
      appBar: AppBar(
        //title: Text('${'voucher'.tr}: 00${newItems.voucherNumber()}'),
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
          // if (!GetPlatform.isDesktop)
          //   IconButton(
          //     onPressed: () async {
          //       // var pdf = await ge(invoice: voucher);
          //       // await Share.shareXFiles([
          //       //   XFile.fromData(pdf)
          //       // ], fileNameOverrides: [
          //       //   '${voucher.customer}-${voucher.invoiceNumber()}.pdf'
          //       // ]);
          //     },
          //     icon: Icon(Icons.share_outlined),
          //   ),
          // IconButton(
          //     onPressed: () async {
          //       // var pdf = await generateInvoice(invoice: voucher);
          //       // Get.to(() => PrintPdfPage(pdfData: pdf));
          //       // final Directory? downloadsDir = await getDownloadsDirectory();
          //       // final Directory? dir = await getExternalStorageDirectory();
          //       // final String newPath =
          //       //     "${dir!.path}/store-management-app"; // مجلد خاص داخل مجلد التطبيق
          //       // final Directory newDir = Directory(newPath);

          //       // if (!await newDir.exists()) {
          //       //   await newDir.create(recursive: true);
          //       // }
          //       // final file = File("${newDir.path}/example.pdf");
          //       // await file.writeAsBytes(await pdf);
          //       //  await savePdfFileToStorage(pdf);
          //     },
          //     icon: Icon(Icons.print))
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
                // Text(
                //     '${'supplier name'.tr}: ${newItems.customer.target?.name}'),
                // Text(newItems.voucherDate()),
                // Text('${'voucher number'.tr}: ${newItems.voucherNumber()}'),
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
                          DataColumn(label: Text('item'.tr)),
                          DataColumn(label: Text('quantity'.tr)),
                          DataColumn(label: Text('Buy Price'.tr)),
                          DataColumn(label: Text('Sell Price'.tr)),
                          DataColumn(label: Text('Total Price'.tr)),
                        ],
                        rows: newItems
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
                Text('Total Price'.tr),
                Expanded(child: verSpace),
                Text(settingsController.currencyFormatter(newItems.fold(
                    0,
                    (previousValue, element) =>
                        previousValue + element.buyPrice))),
              ],
            ),
            verSpace,
            Row(
              children: [
                Text('paid amount'.tr),
                Expanded(child: verSpace),
                // Text(settingsController
                //     .currencyFormatter(newItems.transactions[1].amount)),
              ],
            ),
            verSpace,
            Row(
              children: [
                Text('Supplier Balance'.tr),
                Expanded(child: verSpace),
                // Text(settingsController.currencyFormatter(newItems.balance())),
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
