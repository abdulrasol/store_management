import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/http/stub/file_decoder_stub.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  late SharedPreferences prefs;
  late Rx<String?> appName;
  late Rx<String?> logo;
  late NumberFormat currencyFormat;
  Rx<ThemeMode> appTheme = Rx<ThemeMode>(ThemeMode.system);
  Rx<Locale> appLang = Rx<Locale>(Locale('en'));
  late String countryCode;

  @override
  void onInit() async {
    prefs = await SharedPreferences.getInstance();
    await getAppThemeAndLang();
    await updateSettings();
    super.onInit();
  }

  Future<void> getAppThemeAndLang() async {
    final theme = prefs.getString('app-theme') ?? 'system';
    appLang.value = Locale(prefs.getString('languageCode') ?? 'en',
        prefs.getString('countryCode'));
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

  Future<void> setAppThemeAndLang(
      {String? lang, String? countryCode, String? themeMode}) async {
    prefs.setString('languageCode', lang ?? appLang.value.languageCode);
    prefs.setString(
        'app-theme', themeMode ?? appTheme.value.name.toLowerCase());
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
    // getAppThemeAndLang();
    Get.updateLocale(appLang.value);
  }

  Future<void> updateSettings() async {
    currencyFormat = NumberFormat.currency(
      name: prefs.getString('currency_name') ?? 'USD',
      symbol: prefs.getString('currency_symbol') ?? '\$',
      decimalDigits: prefs.getInt('decimal_digits') ?? 0,
    );
    appName = prefs.getString('store_name').obs;
    logo = prefs.getString('logo').obs;
    if (logo.value == null) {
      logo.value = base64Encode(File('assets/png/logo.png').readAsBytesSync());
    }
  }

  String currencyFormatter(num number) {
    if (number < 0) {
      return '- ${currencyFormat.format(number).split('-')[0]} ${currencyFormat.format(number).split('-')[1]}';
    }

    return currencyFormat.format(number);
  }
}
