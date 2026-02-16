import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  SharedPreferences? prefs;
  Rx<String?> appName = Rx<String?>(null);
  Rx<String?> logo = Rx<String?>(null);
  Rx<String> invoiceTerms = Rx<String>('');
  Rx<String> invoiceFooter = Rx<String>('');
  NumberFormat currencyFormat = NumberFormat.currency(locale: 'ar', name: 'AED', symbol: 'AED', decimalDigits: 0);
  Rx<ThemeMode> appTheme = Rx<ThemeMode>(ThemeMode.system);
  Rx<Locale> appLang = Rx<Locale>(Locale('en'));
  String countryCode = '';

  @override
  void onInit() {
    super.onInit();
    initPrefs();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    await getAppThemeAndLang();
    await updateSettings();
  }

  Future<void> getAppThemeAndLang() async {
    if (prefs == null) return;
    final theme = prefs!.getString('app-theme') ?? 'system';

    appLang.value = Locale(
      prefs!.getString('languageCode') ?? Get.deviceLocale?.languageCode ?? 'en',
      prefs!.getString('countryCode'),
    );
    // Explicitly update locale to ensure it's applied
    Get.updateLocale(appLang.value);

    countryCode = prefs!.getString('countryCode') ?? '';
    switch (theme) {
      case 'dark':
        appTheme.value = ThemeMode.dark;
        break;
      case 'light':
        appTheme.value = ThemeMode.light;
        break;
      case 'system':
        appTheme.value = ThemeMode.system;
        break;
    }
  }

  Future<void> setAppThemeAndLang({String? lang, String? countryCode, String? themeMode}) async {
    if (prefs == null) return;
    prefs!.setString('languageCode', lang ?? appLang.value.languageCode);
    prefs!.setString('app-theme', themeMode ?? appTheme.value.name.toLowerCase());
    if (countryCode != null) {
      prefs!.setString('countryCode', countryCode);
      this.countryCode = countryCode;
    }
    appLang.value = Locale(lang ?? appLang.value.languageCode, countryCode);
    switch (themeMode ?? appTheme.value.name.toLowerCase()) {
      case 'dark':
        appTheme.value = ThemeMode.dark;
        break;
      case 'light':
        appTheme.value = ThemeMode.light;
        break;
      case 'system':
        appTheme.value = ThemeMode.system;
        break;
    }
    Get.updateLocale(appLang.value);
  }

  Future<void> updateSettings() async {
    if (prefs == null) return;
    currencyFormat = NumberFormat.currency(
      locale: prefs!.getString('languageCode') ?? 'en',
      name: prefs!.getString('currency_name') ?? 'AED',
      symbol: prefs!.getString('currency_symbol') ?? 'AED',
      decimalDigits: prefs!.getInt('decimal_digits') ?? 0,
    );
    appName.value = prefs!.getString('store_name');
    invoiceTerms.value = prefs!.getString('invoice_terms') ?? '';
    invoiceFooter.value = prefs!.getString('invoice_footer') ?? '';

    String? logoStr = prefs!.getString('logo');
    if (logoStr == null) {
      try {
        final logoFile = await rootBundle.load('assets/png/logo.png');
        logo.value = base64Encode(logoFile.buffer.asUint8List());
      } catch (e) {
        debugPrint('Error loading default logo: $e');
      }
    } else {
      logo.value = logoStr;
    }
  }

  String currencyFormatter(num number) {
    if (number < 0) {
      return '- ${currencyFormat.format(number).split('-')[0]} ${currencyFormat.format(number).split('-')[1]}';
    }

    return currencyFormat.format(number);
  }
}
