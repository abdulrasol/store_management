import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_management/controllers/database_controller.dart';

class BackupService {
  final DatabaseController dbController = Get.find<DatabaseController>();

  final List<String> jsonFiles = [
    'purchases.json',
    'purchase_categories.json',
    'expense_types.json',
    'employees.json',
    'salaries.json',
    'urgent_orders.json',
  ];

  Future<void> createBackup() async {
    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final jsonName = 'store_backup_$timestamp.json';
      final jsonPath = p.join(tempDir.path, jsonName);

      Map<String, dynamic> backupData = {
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Purchases
      backupData['purchases'] = (await dbController.getPurchases()).map((p) => p.toMap()).toList();

      // Purchase Categories
      backupData['purchase_categories'] = (await dbController.getPurchaseCategories()).map((c) => c.toMap()).toList();

      // Expense Types
      backupData['expense_types'] = (await dbController.getExpenseTypes()).map((t) => t.toMap()).toList();

      // Employees
      backupData['employees'] = (await dbController.getEmployees()).map((e) => e.toMap()).toList();

      // Salaries
      backupData['salaries'] = (await dbController.getSalaries()).map((s) => s.toMap()).toList();

      // Urgent Orders
      backupData['urgent_orders'] = (await dbController.getUrgentOrders()).map((o) => o.toMap()).toList();

      final jsonString = jsonEncode(backupData);
      await File(jsonPath).writeAsString(jsonString);

      await Share.shareXFiles([XFile(jsonPath)], text: 'Store Management JSON Backup');
      Get.snackbar('نجاح', 'تم إنشاء JSON النسخة الاحتياطية بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل النسخ الاحتياطي: $e');
      debugPrint('Backup Error: $e');
    }
  }
  Future<void> restoreBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return;

    File pickedFile = File(result.files.single.path!);

    // Confirm
    bool? confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('استعادة JSON'.tr),
        content: Text('سيتم استبدال جميع بيانات JSON. هل أنت متأكد؟'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('إلغاء'.tr)),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('استعادة'.tr),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final content = await pickedFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final appDocsDir = await getApplicationDocumentsDirectory();

      // Purchases
      if (data['purchases'] != null) {
        final purchases = (data['purchases'] as List).map<Purchase>((m) => Purchase.fromMap(m)).toList();
        await dbController._savePurchases(purchases);
      }

      // Purchase Categories
      if (data['purchase_categories'] != null) {
        final categories = (data['purchase_categories'] as List).map<PurchaseCategory>((m) => PurchaseCategory.fromMap(m)).toList();
        await dbController._savePurchaseCategories(categories);
      }

      // Expense Types
      if (data['expense_types'] != null) {
        final types = (data['expense_types'] as List).map<ExpenseType>((m) => ExpenseType.fromMap(m)).toList();
        await dbController._saveExpenseTypes(types);
      }

      // Employees
      if (data['employees'] != null) {
        final employees = (data['employees'] as List).map<Employee>((m) => Employee.fromMap(m)).toList();
        await dbController._saveEmployees(employees);
      }

      // Salaries
      if (data['salaries'] != null) {
        final salaries = (data['salaries'] as List).map<Salary>((m) => Salary.fromMap(m)).toList();
        await dbController._saveSalaries(salaries);
      }

      // Urgent Orders
      if (data['urgent_orders'] != null) {
        final orders = (data['urgent_orders'] as List).map<UrgentOrder>((m) => UrgentOrder.fromMap(m)).toList();
        await dbController._saveUrgentOrders(orders);
      }

      Get.snackbar('نجاح', 'تمت استعادة JSON بنجاح. أعد تحميل البيانات');
      dbController.loading();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل الاستعادة: $e');
      debugPrint('Restore Error: $e');
    }
  }
}
