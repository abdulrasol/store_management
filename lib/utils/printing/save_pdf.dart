import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> saveFileToExternalStorage(
    List<int> fileBytes, String fileName) async {
  try {
    // 1. التحقق من الأذونات أولاً (مهم جداً)
    bool hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      
        print('لم يتم منح إذن الوصول للتخزين');
     
      return null;
    }
    // 2. الحصول على مسار التخزين الخارجي (مختلف حسب إصدار أندرويد)
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
  
        print('لا يمكن الوصول إلى التخزين الخارجي');
      
      return null;
    }

    // 3. إنشاء مجلد مخصص داخل التخزين الخارجي
    final myAppFolder = Directory('${directory.path}/invoices');
    if (!await myAppFolder.exists()) {
      await myAppFolder.create(recursive: true);
    }

    // 4. إنشاء وحفظ الملف
    final file = File('${myAppFolder.path}/$fileName');
    await file.writeAsBytes(fileBytes);

   
      print('تم حفظ الملف بنجاح في: ${file.path}');
   
    return file.path;
  } catch (e) {
   
      print('حدث خطأ أثناء حفظ الملف: $e');
    
    return null;
  }
}

// دالة للتحقق من أذونات التخزين وطلبها إذا لزم الأمر
Future<bool> _requestStoragePermission() async {
  // للأندرويد 10 (API 29) وما فوق، حالة خاصة
  if (Platform.isAndroid) {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    // يمكن التحقق من الأذونات الإضافية للأندرويد 11 وما فوق
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }
    return false;
  }

  // لأنظمة التشغيل الأخرى
  return true;
}

// دالة للحصول على مسار التخزين الخارجي المناسب
Future<Directory?> getExternalStorageDirectory() async {
  if (Platform.isAndroid) {
    // الحصول على مسار التخزين الخارجي
    final List<Directory>? extDirs = await getExternalStorageDirectories();
    if (extDirs != null && extDirs.isNotEmpty) {
      // سنستخدم أول مسار متاح (عادة بطاقة SD الافتراضية)
      return extDirs.first;
    }
  }

  // إذا لم ينجح، نستخدم مجلد التطبيق (أقل تفضيلاً في هذه الحالة)
  return await getApplicationDocumentsDirectory();
}

// مثال للاستخدام
Future printPdfFileToStorage(Uint8List pdf) async {
  String? filePath = await saveFileToExternalStorage(pdf, 'file.pdf');
  await Printing.layoutPdf(onLayout: (format) => pdf);
  if (filePath != null) {
    // نجح الحفظ، يمكنك عرض رسالة للمستخدم
  
      print('تم حفظ الملف في: $filePath');
    
  }
}

Future sharePdfFile(Uint8List pdf, String? name, int id) async {
  await Share.shareXFiles([XFile.fromData(pdf)],
      fileNameOverrides: ['$name-$id.pdf']);
}
