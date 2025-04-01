import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_management/utils/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _currencyNameController = TextEditingController();
  final TextEditingController _currencySymbolController =
      TextEditingController();
  int decimalDigits = 0;
  String? logoString;

  @override
  void dispose() {
    _storeNameController.dispose();
    _currencyNameController.dispose();
    _currencySymbolController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('store_name', _storeNameController.text);
      await prefs.setString('currency_name', _currencyNameController.text);
      await prefs.setString('currency_symbol', _currencySymbolController.text);
      await prefs.setInt('decimal_digits', decimalDigits);
      await prefs.setBool('onboarding_complete', true);
      if (logoString != null) {
        await prefs.setString('logo', logoString!);
      }
//
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                            color: Colors.blue.withAlpha(33),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.point_of_sale_outlined,
                          size: 80,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Welcome text
                    Text(
                      'welcoming'.tr,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please enter your store information'.tr,
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
                                  XFile? logo = await picker.pickImage(
                                      source: ImageSource.gallery);
                                  if (logo != null) {
                                    File file = File(logo.path);
                                    logoString =
                                        base64Encode(file.readAsBytesSync());
                                  }
                                } else {
                                  const XTypeGroup typeGroup = XTypeGroup(
                                    label: 'images',
                                    extensions: <String>['jpg', 'png'],
                                  );
                                  final XFile? file = await openFile(
                                      acceptedTypeGroups: <XTypeGroup>[
                                        typeGroup
                                      ]);
                                  if (file != null) {
                                    logoString =
                                        base64Encode(await file.readAsBytes());
                                    setState(() {});
                                  }
                                }
                              },
                              // ignore: unnecessary_null_comparison
                              child: Text('Select Store Logo'.tr),
                            )
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: decimalDigits,
                                    onChanged: (int? newValue) {
                                      setState(() {
                                        decimalDigits = newValue!;
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
                          'Save settings and get started'.tr,
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
    );
  }
}
