import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/ui/splash_screen.dart';
import 'package:store_management/ui/home.dart';
import 'package:store_management/utils/app_theme.dart';
import 'package:store_management/utils/app_translations.dart';
import 'controllers/settings_controller.dart';
import 'ui/onboarding_screen.dart' show OnboardingScreen;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.put(SettingsController());

    return Obx(() => GetMaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/home': (context) => Home(),
          },
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: settings.appTheme.value,
          locale: settings.appLang.value,
          translations: AppTranslations(),
          fallbackLocale: const Locale('en'),
        ));
  }
}
