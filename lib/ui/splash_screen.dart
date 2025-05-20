// splash_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/utils/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  SettingsController settingsController = Get.find();

  @override
  void initState() {
    super.initState();
    // done
    // إعداد الرسوم المتحركة للشعار
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // التحقق من حالة الإعدادات بعد تشغيل الرسوم المتحركة
    Future.delayed(const Duration(seconds: 3), () {
      _checkSettings();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingComplete =
        prefs.getBool('onboarding_complete') ?? false;

    final bool appPolicyArgument =
        prefs.getBool('app_policy_argument') ?? false;

    if (!appPolicyArgument) {
      // push app policy dialog
      await Get.dialog(appPolicyDialog());
    }
    if (!mounted) return;

    if (onboardingComplete) {
      // إذا تم إكمال شاشة البداية سابقًا، انتقل إلى الشاشة الرئيسية
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // إذا كانت هذه المرة الأولى، انتقل إلى شاشة البداية
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  Directionality appPolicyDialog() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'App Policy',
                style: TextStyle(fontSize: 18),
              ),
              verSpace,
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    policy,
                    // textDirection: TextDirection.ltr,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => exit(0),
                    label: Text('Disagree'.tr),
                    // icon: Icon(Icons),
                  ),
                  const SizedBox(width: 5),
                  TextButton.icon(
                    onPressed: () async {
                      _policyUpdate(true);
                    },
                    label: Text('Agree'.tr),
                    // icon: Icon(Icons),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _policyUpdate(bool appPolicyArgument) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_policy_argument', appPolicyArgument);
    if (!mounted) return;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار متحرك
              ScaleTransition(
                scale: _animation,
                child: FadeTransition(
                  opacity: _animation,
                  child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: settingsController.logo.value != null
                          ? SizedBox(
                              width: 120,
                              height: 120,
                              child: Image.memory(
                                base64Decode(settingsController.logo.value!),
                                fit: BoxFit.contain,
                              ),
                            )
                          : Icon(
                              Icons.point_of_sale_outlined,
                              size: 80,
                              color: Colors.blue.shade700,
                            )),
                ),
              ),

              const SizedBox(height: 40),

              // اسم التطبيق
              FadeTransition(
                opacity: _animation,
                child: Text(
                  'Sales Management App'.tr,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // شعار التطبيق
              FadeTransition(
                opacity: _animation,
                child: Text(
                  'Manage your store easily and efficiently'
                      .tr, //  'إدارة متجرك بسهولة وكفاءة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withAlpha(229),
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // مؤشر التحميل
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
