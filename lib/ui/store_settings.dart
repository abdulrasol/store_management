import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/expense.dart';
import 'package:store_management/models/purchase.dart';
import 'package:store_management/services/backup_service.dart';
import 'package:store_management/utils/app_constants.dart';

//DatabaseController databaseController = Get.find(); //put(DatabaseController());
SettingsController settingsController = Get.find();

class StoreSettings extends StatefulWidget {
  const StoreSettings({super.key});

  @override
  StoreSettingsState createState() => StoreSettingsState();
}

class StoreSettingsState extends State<StoreSettings> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _currencyNameController = TextEditingController();
  final TextEditingController _currencySymbolController = TextEditingController();
  final TextEditingController _invoiceTermsController = TextEditingController();
  final TextEditingController _invoiceFooterController = TextEditingController();
  int _decimalDigits = 0;
  String? logoString;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storeNameController.text = prefs.getString('store_name') ?? '';
      _currencyNameController.text = prefs.getString('currency_name') ?? '';
      _currencySymbolController.text = prefs.getString('currency_symbol') ?? '';
      _invoiceTermsController.text = prefs.getString('invoice_terms') ?? '';
      _invoiceFooterController.text = prefs.getString('invoice_footer') ?? '';
      _decimalDigits = prefs.getInt('decimal_digits') ?? 0;
      logoString = prefs.getString('logo');
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _currencyNameController.dispose();
    _currencySymbolController.dispose();
    _invoiceTermsController.dispose();
    _invoiceFooterController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('store_name', _storeNameController.text);
      await prefs.setString('currency_name', _currencyNameController.text);
      await prefs.setString('currency_symbol', _currencySymbolController.text);
      await prefs.setString('invoice_terms', _invoiceTermsController.text);
      await prefs.setString('invoice_footer', _invoiceFooterController.text);
      await prefs.setInt('decimal_digits', _decimalDigits);
      // await prefs.setBool('onboarding_complete', false);
      if (logoString != null) {
        await prefs.setString('logo', logoString!);
      }
      Get.appUpdate();
      if (!mounted) return;
      Navigator.of(context).pop(); // العودة إلى الشاشة السابقة بعد الحفظ
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Store Information'.tr), // عنوان الشاشة
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
              // gradient: LinearGradient(
              //   begin: Alignment.topCenter,
              //   end: Alignment.bottomCenter,
              //   colors: [
              //     Colors.blue.shade50,
              //     Colors.white,
              //   ],
              // ),
              ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withAlpha(80),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: logoString == null
                              ? Icon(
                                  Icons.point_of_sale_outlined,
                                  size: 80,
                                  color: Colors.blue.shade700,
                                )
                              : SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Image.memory(
                                    base64Decode(logoString!),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Welcome text
                      Text(
                        'Reset your settings'.tr, // تغيير النص
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please re-enter your store information'.tr, // تغيير النص
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Store Name
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Store Information'.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _storeNameController,
                                decoration: InputDecoration(
                                  labelText: 'Store Name'.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  prefixIcon: const Icon(Icons.store),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter store name'.tr;
                                  }
                                  return null;
                                },
                              ),
                              verSpace,
                              OutlinedButton(
                                  onPressed: () async {
                                    if (!GetPlatform.isDesktop) {
                                      final ImagePicker picker = ImagePicker();
                                      XFile? logo = await picker.pickImage(source: ImageSource.gallery);
                                      if (logo != null) {
                                        File file = File(logo.path);
                                        logoString = base64Encode(file.readAsBytesSync());
                                      }
                                    } else {
                                      const XTypeGroup typeGroup = XTypeGroup(
                                        label: 'images',
                                        extensions: <String>['jpg', 'png'],
                                      );
                                      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
                                      if (file != null) {
                                        logoString = base64Encode(await file.readAsBytes());
                                        setState(() {});
                                      }
                                    }
                                  },
                                  child: Text(logoString != null ? 'Change Logo'.tr : 'Select Store Logo'.tr))
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Currency Settings
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Currency Settings'.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _currencyNameController,
                                decoration: InputDecoration(
                                  labelText: 'Currency name'.tr,
                                  hintText: 'Example: Iraqi dinar'.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  prefixIcon: const Icon(Icons.payments),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the currency name'.tr;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _currencySymbolController,
                                decoration: InputDecoration(
                                  labelText: 'currency symbol'.tr,
                                  hintText: 'Example: IQD'.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  prefixIcon: const Icon(Icons.attach_money),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the currency code'.tr;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Text('Number of decimal places:'.tr),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      value: _decimalDigits,
                                      onChanged: (int? newValue) {
                                        setState(() {
                                          _decimalDigits = newValue!;
                                        });
                                      },
                                      items: [0, 1, 2, 3]
                                          .map<DropdownMenuItem<int>>(
                                            (int value) => DropdownMenuItem<int>(
                                              value: value,
                                              child: Text('$value'),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Settings'.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<ThemeMode>(
                                initialValue: Get.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                                decoration: InputDecoration(
                                  labelText: 'App Theme'.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  prefixIcon: const Icon(Icons.brightness_auto),
                                ),
                                items: [
                                  DropdownMenuItem<ThemeMode>(
                                    value: ThemeMode.dark,
                                    child: Text('Dark Theme'.tr),
                                  ),
                                  DropdownMenuItem<ThemeMode>(
                                    value: ThemeMode.light,
                                    child: Text('Light Theme'.tr),
                                  ),
                                  DropdownMenuItem<ThemeMode>(
                                    value: ThemeMode.system,
                                    child: Text('Follow System'.tr),
                                  ),
                                ],
                                onChanged: (ThemeMode? value) async {
                                  Get.changeThemeMode(value!);
                                  final prefs = await SharedPreferences.getInstance();
                                  //    print(value.name);
                                  prefs.setString('app-theme', value.name);
                                },
                              ),
                              verSpace,
                              DropdownButtonFormField<String>(
                                initialValue: Get.locale?.languageCode ?? '',
                                decoration: InputDecoration(
                                  labelText: 'App Language'.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  prefixIcon: const Icon(Icons.language),
                                ),
                                items: _langs,
                                onChanged: (String? value) async {
                                  Get.updateLocale(Locale(value ?? 'en'));
                                  final prefs = await SharedPreferences.getInstance();

                                  prefs.setString('languageCode', value!);
                                  Get.updateLocale(Locale(value));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice Customization'.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _invoiceTermsController,
                                decoration: InputDecoration(
                                  labelText: 'Variables / Terms'.tr,
                                  hintText: 'e.g. Warranty details'.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  prefixIcon: const Icon(Icons.description),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _invoiceFooterController,
                                decoration: InputDecoration(
                                  labelText: 'Footer Message'.tr,
                                  hintText: 'e.g. Thank you for your business!'.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  prefixIcon: const Icon(Icons.short_text),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.security, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Data Safety'.tr,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.download, color: Colors.teal),
                                title: Text('Backup Data'.tr),
                                subtitle: Text('Save a copy of your data'.tr),
                                onTap: () async {
                                  await BackupService().createBackup();
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.restore, color: Colors.orange),
                                title: Text('Restore Data'.tr),
                                subtitle: Text('Restore from a backup file'.tr),
                                onTap: () async {
                                  await BackupService().restoreBackup();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إعدادات المشتريات'.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.category, color: Colors.blue),
                                title: Text('فئات المشتريات'.tr),
                                subtitle: Text('إدارة قائمة فئات المشتريات'.tr),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => _showPurchaseCategoriesDialog(),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.receipt_long, color: Colors.orange),
                                title: Text('أنواع المصروفات'.tr),
                                subtitle: Text('إدارة قائمة أنواع المصروفات'.tr),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => _showExpenseTypesDialog(),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.backup, color: Colors.green),
                                title: Text('نسخ احتياطي'.tr),
                                subtitle: Text('إنشاء واستعادة نسخة احتياطية كاملة'.tr),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: _showBackupDialog,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Data Management
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Management'.tr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.category, color: Colors.blue),
                                title: Text('فئات المشتريات'.tr),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: _showPurchaseCategoriesDialog,
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.money_off, color: Colors.orange),
                                title: Text('أنواع المصروفات'.tr),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: _showExpenseTypesDialog,
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.backup, color: Colors.green),
                                title: Text('النسخ الاحتياطي والاستعادة'.tr),
                                subtitle: Text('حفظ واستعادة بيانات التطبيق'.tr),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: _showBackupDialog,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            'Save settings'.tr, // تغيير النص
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final List<DropdownMenuItem<String>> _langs = const [
    DropdownMenuItem<String>(
      value: 'ar',
      child: Text('العربية'),
    ),
    DropdownMenuItem<String>(
      value: 'en',
      child: Text('English'),
    ),
  ];

  // ==================== EXPENSE TYPES ====================

  void _showBackupDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.backup, color: Colors.green),
            const SizedBox(width: 8),
            Text('نسخ احتياطي واستعادة'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await BackupService().createBackup();
                Get.back();
              },
              icon: const Icon(Icons.file_download, color: Colors.white),
              label: Text('إنشاء نسخة احتياطية'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await BackupService().restoreBackup();
                Get.back();
              },
              icon: const Icon(Icons.file_upload, color: Colors.white),
              label: Text('استعادة نسخة احتياطية'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إغلاق'.tr),
          ),
        ],
      ),
    );
  }

  void _showExpenseTypesDialog() {
    final DatabaseController databaseController = Get.find<DatabaseController>();

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Colors.orange),
            const SizedBox(width: 8),
            Text('أنواع المصروفات'.tr),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<ExpenseType>>(
            future: databaseController.getExpenseTypes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final types = snapshot.data!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAddExpenseTypeDialog(databaseController),
                    icon: const Icon(Icons.add),
                    label: Text('إضافة نوع جديد'.tr),
                  ),
                  const SizedBox(height: 16),
                  types.isEmpty
                      ? Text('لا توجد أنواع'.tr)
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: types.length,
                          itemBuilder: (context, index) {
                            final type = types[index];
                            return ListTile(
                              title: Text(type.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditExpenseTypeDialog(
                                      databaseController,
                                      type,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteExpenseType(
                                      databaseController,
                                      type,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إغلاق'.tr),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseTypeDialog(DatabaseController controller) {
    final TextEditingController nameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('إضافة نوع مصروف جديد'.tr),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'اسم النوع'.tr,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final type = ExpenseType(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                );
                await controller.addExpenseType(type);
                Get.back();
                _showExpenseTypesDialog();
                Get.snackbar(
                  'نجاح'.tr,
                  'تم إضافة النوع بنجاح'.tr,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: Text('حفظ'.tr),
          ),
        ],
      ),
    );
  }

  void _showEditExpenseTypeDialog(DatabaseController controller, ExpenseType type) {
    final TextEditingController nameController = TextEditingController(text: type.name);

    Get.dialog(
      AlertDialog(
        title: Text('تعديل نوع المصروف'.tr),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'اسم النوع'.tr,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final updated = ExpenseType(
                  id: type.id,
                  name: nameController.text,
                );
                await controller.updateExpenseType(updated);
                Get.back();
                _showExpenseTypesDialog();
                Get.snackbar(
                  'نجاح'.tr,
                  'تم تحديث النوع بنجاح'.tr,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: Text('حفظ'.tr),
          ),
        ],
      ),
    );
  }

  void _deleteExpenseType(DatabaseController controller, ExpenseType type) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('تأكيد الحذف'.tr),
        content: Text('هل أنت متأكد من حذف ${type.name}؟'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف'.tr),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.deleteExpenseType(type.id);
      _showExpenseTypesDialog();
      Get.snackbar(
        'نجاح'.tr,
        'تم حذف النوع بنجاح'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  // ==================== PURCHASE CATEGORIES ====================

  void _showPurchaseCategoriesDialog() {
    final DatabaseController databaseController = Get.find<DatabaseController>();
    
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.category, color: Colors.blue),
            const SizedBox(width: 8),
            Text('فئات المشتريات'.tr),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<PurchaseCategory>>(
            future: databaseController.getPurchaseCategories(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final categories = snapshot.data!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add New Category
                  ElevatedButton.icon(
                    onPressed: () => _showAddCategoryDialog(databaseController),
                    icon: const Icon(Icons.add),
                    label: Text('إضافة فئة جديدة'.tr),
                  ),
                  const SizedBox(height: 16),
                  // Categories List
                  categories.isEmpty
                      ? Text('لا توجد فئات'.tr)
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return ListTile(
                              title: Text(category.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditCategoryDialog(
                                      databaseController,
                                      category,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteCategory(
                                      databaseController,
                                      category,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إغلاق'.tr),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(DatabaseController controller) {
    final TextEditingController nameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('إضافة فئة جديدة'.tr),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'اسم الفئة'.tr,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final category = PurchaseCategory(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                );
                await controller.addPurchaseCategory(category);
                Get.back();
                _showPurchaseCategoriesDialog(); // Refresh
                Get.snackbar(
                  'نجاح'.tr,
                  'تم إضافة الفئة بنجاح'.tr,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: Text('حفظ'.tr),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(DatabaseController controller, PurchaseCategory category) {
    final TextEditingController nameController = TextEditingController(text: category.name);

    Get.dialog(
      AlertDialog(
        title: Text('تعديل فئة'.tr),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'اسم الفئة'.tr,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final updated = PurchaseCategory(
                  id: category.id,
                  name: nameController.text,
                );
                await controller.updatePurchaseCategory(updated);
                Get.back();
                _showPurchaseCategoriesDialog(); // Refresh
                Get.snackbar(
                  'نجاح'.tr,
                  'تم تحديث الفئة بنجاح'.tr,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: Text('حفظ'.tr),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(DatabaseController controller, PurchaseCategory category) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('تأكيد الحذف'.tr),
        content: Text('هل أنت متأكد من حذف ${category.name}؟'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف'.tr),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.deletePurchaseCategory(category.id);
      _showPurchaseCategoriesDialog(); // Refresh
      Get.snackbar(
        'نجاح'.tr,
        'تم حذف الفئة بنجاح'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  void _showBackupDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.settings_backup_restore, color: Colors.blue),
            const SizedBox(width: 8),
            Text('النسخ الاحتياطي والاستعادة'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.download, color: Colors.white),
              ),
              title: Text('إنشاء نسخة احتياطية'.tr),
              subtitle: Text('تصدير جميع البيانات إلى ملف'.tr),
              onTap: () async {
                Get.back();
                final backupService = BackupService();
                await backupService.createBackup();
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.upload, color: Colors.white),
              ),
              title: Text('استعادة نسخة احتياطية'.tr),
              subtitle: Text('استيراد البيانات من ملف'.tr),
              onTap: () async {
                Get.back();
                final backupService = BackupService();
                await backupService.restoreBackup();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إغلاق'.tr),
          ),
        ],
      ),
    );
  }
}
