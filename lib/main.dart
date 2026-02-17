import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:store_management/ui/splash_screen.dart';
import 'package:store_management/ui/home.dart';
import 'package:store_management/utils/app_theme.dart';
import 'package:store_management/utils/app_translations.dart';
import 'dart:io';
import 'controllers/settings_controller.dart';
import 'ui/onboarding_screen.dart' show OnboardingScreen;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final settings = Get.put(SettingsController());

        final baseTextScale = constraints.maxWidth > 600 ? 1.0 : 0.95;
        final isSmallScreen = constraints.maxWidth < 360;

        return Obx(() => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(baseTextScale * (isSmallScreen ? 0.9 : 1.0)),
                alwaysUse24HourFormat: true,
              ),
              child: GetMaterialApp(
                initialRoute: '/',
                routes: {
                  '/': (context) => const SplashScreen(),
                  '/onboarding': (context) => const OnboardingScreen(),
                  '/home': (context) => const Home(),
                },
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme(),
                darkTheme: AppTheme.darkTheme(),
                themeMode: settings.appTheme.value,
                locale: settings.appLang.value,
                translations: AppTranslations(),
                fallbackLocale: const Locale('en'),
                builder: (context, child) {
                  return Directionality(
                    textDirection: settings.appLang.value.languageCode == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: child!,
                  );
                },
              ),
            ));
      },
    );
  }
}
