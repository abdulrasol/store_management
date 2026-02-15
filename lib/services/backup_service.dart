import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/expense.dart';
import 'package:store_management/models/inventory.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/purchase.dart';
import 'package:store_management/models/salary.dart';
import 'package:store_management/models/urgent_order.dart';

class BackupService {
  final DatabaseController _db = Get.find<DatabaseController>();

  Future<Map<String, dynamic>> _collectAllData() async {
    return {
      'metadata': {
        'version': '1.0',
        'createdAt': DateTime.now().toIso8601String(),
        'appName': 'Store Management',
      },
      'purchases': (await _db.getPurchases()).map((e) => e.toMap()).toList(),
      'purchaseCategories': (await _db.getPurchaseCategories()).map((e) => e.toMap()).toList(),
      'expenses': _db.expenses.map((e) => {
        'description': e.description,
        'amount': e.amount,
        'date': e.date.toIso8601String(),
      }).toList(),
      'expenseTypes': (await _db.getExpenseTypes()).map((e) => e.toMap()).toList(),
      'employees': (await _db.getEmployees()).map((e) => e.toMap()).toList(),
      'salaries': (await _db.getSalaries()).map((e) => e.toMap()).toList(),
      'salaryAdvances': (await _db.getSalaryAdvances()).map((e) => e.toMap()).toList(),
      'urgentOrders': await _db.getUrgentOrders().then((list) => list.map((e) => e.toMap()).toList()),
      'paperStock': (await _db.getPaperStock()).map((e) => e.toMap()).toList(),
      'inkStock': (await _db.getInkStock()).map((e) => e.toMap()).toList(),
      // Add other models as needed (invoices, items, etc. if they are in JSON)
    };
  }

  Future<void> createBackup() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final data = await _collectAllData();
      final jsonString = jsonEncode(data);
      
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'store_backup_$dateStr.json';
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonString);

      Get.back(); // Close loading

      await Share.shareXFiles([XFile(file.path)], text: 'نسخة احتياطية - $dateStr');
      
    } catch (e) {
      Get.back(); // Close loading if error
      Get.snackbar(
        'خطأ'.tr,
        'فشل إنشاء النسخة الاحتياطية: $e'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      Get.dialog(
        AlertDialog(
          title: Text('تأكيد الاستعادة'.tr),
          content: Text('سيتم استبدال البيانات الحالية بالبيانات الموجودة في ملف النسخ الاحتياطي. هل أنت متأكد؟'.tr),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('إلغاء'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _processRestore(data);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('استعادة'.tr),
            ),
          ],
        ),
      );

    } catch (e) {
      Get.snackbar(
        'خطأ'.tr,
        'ملف غير صالح أو تالف'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _processRestore(Map<String, dynamic> data) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // 1. Purchases
      if (data.containsKey('purchases')) {
        final List<dynamic> list = data['purchases'];
        final items = list.map((e) => Purchase.fromMap(e)).toList();
        await _db.savePurchases(items);
      }

      // 2. Purchase Categories
      if (data.containsKey('purchaseCategories')) {
        final List<dynamic> list = data['purchaseCategories'];
        final items = list.map((e) => PurchaseCategory.fromMap(e)).toList();
        await _db.savePurchaseCategories(items);
      }

      // 3. Employees
      if (data.containsKey('employees')) {
        final List<dynamic> list = data['employees'];
        final items = list.map((e) => Employee.fromMap(e)).toList();
        await _db.saveEmployees(items);
      }

      // 4. Salaries
      if (data.containsKey('salaries')) {
        final List<dynamic> list = data['salaries'];
        final items = list.map((e) => Salary.fromMap(e)).toList();
        await _db.saveSalaries(items);
      }

      // 5. Salary Advances
      if (data.containsKey('salaryAdvances')) {
        final List<dynamic> list = data['salaryAdvances'];
        final items = list.map((e) => SalaryAdvance.fromMap(e)).toList();
        await _db.saveSalaryAdvances(items);
      }

      // 6. Expenses
      if (data.containsKey('expenses')) {
        final List<dynamic> list = data['expenses'];
        final items = list.map((e) => Expense(
          description: e['description'],
          amount: (e['amount'] as num).toDouble(),
          date: DateTime.parse(e['date']),
        )).toList();
        await _db.saveExpenses(items);
      }

      // 7. Expense Types
      if (data.containsKey('expenseTypes')) {
        final List<dynamic> list = data['expenseTypes'];
        final items = list.map((e) => ExpenseType.fromMap(e)).toList();
        await _db.saveExpenseTypes(items);
      }

      // 7. Urgent Orders
      if (data.containsKey('urgentOrders')) {
        final List<dynamic> list = data['urgentOrders'];
        final items = list.map((e) => UrgentOrder.fromMap(e)).toList();
        await _db.saveUrgentOrders(items);
      }
      
      // 8. Paper Stock
      if (data.containsKey('paperStock')) {
        final List<dynamic> list = data['paperStock'];
        final items = list.map((e) => PaperStock.fromMap(e)).toList();
        await _db.savePaperStock(items);
      }
      
      // 9. Ink Stock
      if (data.containsKey('inkStock')) {
        final List<dynamic> list = data['inkStock'];
        final items = list.map((e) => InkStock.fromMap(e)).toList();
        await _db.saveInkStock(items);
      }

      // Note: ObjectBox data (Invoices, Items) handle separately if needed
      // Currently focusing on JSON-based data as requested for "All in one JSON" models

      Get.back(); // Close loading
      
      // Refresh Data
      _db.loading(); 
      Get.find<SettingsController>().update(); // Refresh UI if listening

      Get.snackbar(
        'نجاح'.tr,
        'تم استعادة البيانات بنجاح'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.back();
      Get.snackbar(
        'خطأ'.tr,
        'فشل الاستعادة: $e'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}