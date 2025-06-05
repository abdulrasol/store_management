/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/utils/app_constants.dart';

Future<Uint8List> generateFullInvoice({required Customer customer}) async {
  final invoiceTamplate = InvoiceTamplate(
    customer: customer,

    paymentInfo:
        '4509 Wiseman Street\nKnoxville, Tennessee(TN), 37929\n865-372-0425',
    //tax: .15,
    baseColor: PdfColors.teal,
    accentColor: PdfColors.blueGrey900,
  );

  return await invoiceTamplate.buildPdf(PdfPageFormat.a4);
}

class InvoiceTamplate {
  InvoiceTamplate({
    required this.customer,
    required this.paymentInfo,
    required this.baseColor,
    required this.accentColor,
  });

  final String paymentInfo;
  final PdfColor baseColor;
  final PdfColor accentColor;
  final Customer customer;
  SettingsController settingsController = Get.find();

  static const _darkColor = PdfColors.blueGrey800;
  static const _lightColor = PdfColors.white;

  PdfColor get _accentTextColor => baseColor.isLight ? _lightColor : _darkColor;

  Uint8List? logo;
  Uint8List? name;

  Future<Uint8List> buildPdf(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();

    final fontDataRegular =
        await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final fontDataBold = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final fontDataLight = await rootBundle.load('assets/fonts/Cairo-Light.ttf');

    final fullBackFont =
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf');

    final img = await rootBundle.load('assets/png/logo.png');
    logo = settingsController.logo.value != null
        ? base64Decode(settingsController.logo.value!)
        : img.buffer.asUint8List();
    // Add page to the PDF
    doc.addPage(
      pw.MultiPage(
        pageTheme: _buildTheme(
          pageFormat,
          pw.Font.ttf(fontDataRegular),
          pw.Font.ttf(fontDataBold),
          pw.Font.ttf(fontDataLight),
          pw.Font.ttf(fullBackFont),
          //   await PdfGoogleFonts.tajawalRegular(),
          //  await PdfGoogleFonts.tajawalBold(),
          //  await PdfGoogleFonts.tajawalMedium(),
        ),
        header: _buildHeader,
        footer: _buildFooter,
        build: (context) => [
          _contentHeader(context),
          _contentTable(context),
          pw.SizedBox(height: 20),
          _contentFooter(context),
          pw.SizedBox(height: 20),
        ],
      ),
    );

    // Return the PDF file content
    return doc.save();
  }

  pw.Widget _buildHeader(
    pw.Context context,
  ) {
    return pw.Container(
        decoration: pw.BoxDecoration(
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          color: PdfColors.white,
        ),
        padding: const pw.EdgeInsets.only(bottom: 20, right: 10),
        alignment: pw.Alignment.centerLeft,
        width: double.infinity,
        //height: 100,
        child: pw.Directionality(
          textDirection:
              getTextDirection(settingsController.appName.value ?? ''),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Expanded(
                  child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text(settingsController.appName.value ?? '',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text(shortSlag, style: pw.TextStyle()),
                    pw.SizedBox(height: 10),
                  ],
                ),
              )),
              pw.Container(
                //  alignment: pw.Alignment.topRight,
                //height: 250,
                child: logo != null
                    ? pw.Image(pw.MemoryImage(logo!), width: 100)
                    : pw.PdfLogo(),
              ),
            ],
          ),
        ));
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          height: 20,
          width: 100,
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.pdf417(),
            data: 'customer id : ${customer.id}',
            drawText: false,
          ),
        ),
        pw.Text(
          'Page ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.white,
          ),
        ),
      ],
    );
  }

  pw.PageTheme _buildTheme(PdfPageFormat pageFormat, pw.Font base, pw.Font bold,
      pw.Font italic, pw.Font fullBackFont) {
    return pw.PageTheme(
        pageFormat: pageFormat,
        theme: pw.ThemeData(
          defaultTextStyle: pw.TextStyle(
              font: base, fontBold: base, fontFallback: [fullBackFont]),
        )
        // theme: pw.ThemeData.withFont(
        //   base: base,
        //   bold: bold,
        //   italic: italic,
        //   fontFallback: [fullBackFont],
        // ).copyWith(defaultTextStyle: pw.TextStyle(fontFallback: [fullBackFont])),
        // buildBackground: (context) => pw.FullPage(
        //   ignoreMargins: true,
        //   child: pw.SvgImage(svg: _bgShape!),
        // ),
        );
  }

  pw.Widget _contentHeader(pw.Context context) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        color: accentColor,
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: pw.EdgeInsets.only(bottom: 10),
      alignment: pw.Alignment.centerLeft,
      // height: 50,
      child: pw.DefaultTextStyle(
          style: pw.TextStyle(
            color: _accentTextColor,
            fontSize: 12,
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Full Account Statement',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Row(children: [
                          pw.Text(
                            'Invoice to: ',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Directionality(
                            textDirection: getTextDirection(customer.name),
                            child: pw.Text(
                              customer.name,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        ]),
                        pw.Text(
                          'Phone: ${customer.phone}',
                          style: pw.TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                            'invoice date: ${DateTime.now().toString().substring(0, 16)}'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }

  pw.Widget _contentFooter(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.DefaultTextStyle(
            style: const pw.TextStyle(
              fontSize: 10,
              color: _darkColor,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Divider(color: baseColor),
                pw.DefaultTextStyle(
                  style: pw.TextStyle(
                    color: baseColor,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Customer Balance:'),
                      pw.Text(
                          settingsController
                              .currencyFormatter(customer.balance())
                              .replaceAll('\u200F', ''),
                          textDirection: getTextDirection(settingsController
                              .currencyFormat.currencySymbol)),
                    ],
                  ),
                ),
                pw.Divider(color: baseColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _contentTable(pw.Context context) {
    return pw.Table(
      columnWidths: {
        //     0: pw.FlexColumnWidth(2), // تخصيص عرض العمود الأول
        //   1: pw.FlexColumnWidth(1),
        //   2: pw.FlexColumnWidth(1),
      },
      children: [
        // الصف الأول (العناوين)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: baseColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Transaction Number',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Transaction Date',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Transaction Type',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Transaction Amount',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
        // توليد الصفوف تلقائيًا بناءً على عدد العناصر
        ...customer.trasnsactions.map(
          (trasnsaction) => pw.TableRow(
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: accentColor)),
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(trasnsaction.transactionNumber(),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(trasnsaction.paymentDate(),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Directionality(
                textDirection: getTextDirection(trasnsaction.stringType()),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(trasnsaction.stringType(),
                      textAlign: pw.TextAlign.center),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                    settingsController
                        .currencyFormatter(trasnsaction.amount)
                        .replaceAll('\u200F', ''),
                    textAlign: pw.TextAlign.center,
                    textDirection: getTextDirection(
                        settingsController.currencyFormat.currencySymbol)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

pw.TextDirection getTextDirection(String text) {
  final arabicRegex = RegExp(r'[\u0600-\u06FF]');
  return arabicRegex.hasMatch(text)
      ? pw.TextDirection.rtl
      : pw.TextDirection.ltr;
}
