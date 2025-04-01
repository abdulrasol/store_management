import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/ui/invoice_update.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:store_management/utils/printing/invoice_pdf.dart';
import 'package:store_management/utils/printing/save_pdf.dart';

class InvoiceView extends StatelessWidget {
  const InvoiceView({super.key, required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    print(Get.previousRoute);
    SettingsController settingsController = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: Text('invoice-id'.trParams({'id': invoice.id.toString()})),
        leading: IconButton(
            onPressed: () {
              if (Get.previousRoute == '/InvoiceSave' ||
                  Get.previousRoute == '/InvoiceSaveUpdate') {
                Get.close(3);
              }
              //print(Get.previousRoute);
              Get.back();
            },
            icon: Icon(Icons.arrow_back)),
        actions: [
          IconButton(
            tooltip: 'Edit Invoice'.tr,
            onPressed: () async {
              Get.to(() => InvoiceUpdate(invoice: invoice));
            },
            icon: Icon(Icons.edit_square),
          ),
          if (!GetPlatform.isDesktop)
            IconButton(
              onPressed: () async {
                //var pdf = await generateInvoice(invoice: invoice);
                await sharePdfFile(await generateInvoice(invoice: invoice),
                    invoice.customer.target?.name, invoice.id);
              },
              icon: Icon(Icons.share_outlined),
            ),
          IconButton(
              onPressed: () async {
                ///var pdf = await generateInvoice(invoice: invoice);
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
                await printPdfFileToStorage(
                    await generateInvoice(invoice: invoice));
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
                Text('customer_name'
                    .trParams({'name': invoice.customer.target?.name ?? ''})),
                Text(invoice.invoiceDate()),
                Text(invoice.invoiceNumber()),
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
                          DataColumn(label: Text('Price'.tr)),
                          DataColumn(label: Text('discount'.tr)),
                          DataColumn(label: Text('Total Price'.tr)),
                        ],
                        rows: invoice.items
                            .map<DataRow>((item) => DataRow(
                                  cells: [
                                    DataCell(Text(item.item.target!.name)),
                                    DataCell(
                                        Text(item.quantity.toStringAsFixed(0))),
                                    DataCell(
                                        Text(item.itemSellPrice.toString())),
                                    DataCell(
                                        Text(item.discount.toStringAsFixed(0))),
                                    DataCell(Text(
                                        item.totalPrice().toStringAsFixed(0))),
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
                Text(settingsController.currencyFormatter(invoice.price())),
              ],
            ),
            verSpace,
            Row(
              children: [
                Text('discount'.tr),
                Expanded(child: verSpace),
                Text(settingsController.currencyFormatter(invoice.discount())),
              ],
            ),
            verSpace,
            Row(children: [
              Text('price to pay'.tr),
              Expanded(child: verSpace),
              Text(settingsController.currencyFormatter(invoice.pricetoPay())),
            ]),
            verSpace,
            Row(
              children: [
                Text('paid amount'.tr),
                Expanded(child: verSpace),
                Text(settingsController
                    .currencyFormatter(invoice.transactions[1].amount)),
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
