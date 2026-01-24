import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_management/controllers/settings_controller.dart';
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

  final List<DropdownMenuItem<String>> _langs = [
    DropdownMenuItem<String>(
      value: 'ar',
      child: const Text('العربية'),
    ),
    DropdownMenuItem<String>(
      value: 'en',
      child: const Text('English'),
    ),
    DropdownMenuItem<String>(
      value: 'fa',
      child: const Text('فارسى'),
    ),
    DropdownMenuItem<String>(
      value: 'tr',
      child: const Text('Türkçe'),
    ),
    DropdownMenuItem<String>(
      value: 'zh',
      child: const Text('简体中文'),
    ),
    DropdownMenuItem<String>(
      value: 'es',
      child: const Text('Español'),
    ),
    DropdownMenuItem<String>(
      value: 'fr',
      child: const Text('Français'),
    ),
    DropdownMenuItem<String>(
      value: 'de',
      child: const Text('Deutsch'),
    ),
    DropdownMenuItem<String>(
      value: 'ru',
      child: const Text('Русский'),
    ),
    DropdownMenuItem<String>(
      value: 'pt',
      child: const Text('Português'),
    ),
    DropdownMenuItem<String>(
      value: 'hi',
      child: const Text('हिन्दी'),
    ),
    DropdownMenuItem<String>(
      value: 'id',
      child: const Text('Indonesia'),
    ),
    DropdownMenuItem<String>(
      value: 'it',
      child: const Text('Italiano'),
    ),
    DropdownMenuItem<String>(
      value: 'th',
      child: const Text('ไทย'),
    ),
    DropdownMenuItem<String>(
      value: 'pl',
      child: const Text('Polski'),
    ),
    DropdownMenuItem<String>(
      value: 'ro',
      child: const Text('Română'),
    ),
  ];
}
