import 'package:flutter/foundation.dart';

import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

//مثال للاستخدام
Future printPdfFileToStorage(Uint8List pdf) async {
  await Printing.layoutPdf(onLayout: (format) => pdf);
}

Future sharePdfFile(Uint8List pdf, String? name, int id) async {
  await Share.shareXFiles([XFile.fromData(pdf)],
      fileNameOverrides: ['$name-$id.pdf']);
}
