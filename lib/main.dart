import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/database/objectbox.dart';
import 'package:store_management/ui/splash_screen.dart';
import 'package:store_management/ui/home.dart';
import 'package:store_management/utils/app_theme.dart';
import 'package:store_management/utils/app_translations.dart';
import 'controllers/settings_controller.dart';
import 'ui/onboarding_screen.dart' show OnboardingScreen;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = Get.put(DatabaseController());
  Get.put(SettingsController());
  final objectBox = await ObjectBox.create();
  await database.init(objectBox);

  runApp(app);
}

final app = GetMaterialApp(
  title: 'welcoming'.tr,
  initialRoute: '/',
  routes: {
    '/': (context) => const SplashScreen(),
    '/onboarding': (context) => const OnboardingScreen(),
    '/home': (context) => const Home(),
  },
  debugShowCheckedModeBanner: false,
  theme: AppTheme.lightTheme(),
  darkTheme: AppTheme.darkTheme(),
  themeMode: ThemeMode.system,
  locale: Get.deviceLocale, // Locale('ar'), //
  translations: AppTranslations(),
  fallbackLocale: Locale('en', 'US'),
);
