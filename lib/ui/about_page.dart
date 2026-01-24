import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:store_management/controllers/settings_controller.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final settingsController = Get.find<SettingsController>();
  String _version = "";
  String _buildNumber = "";

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'.tr),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // App Logo & Info
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront, size: 60, color: Colors.teal),
            ),
            const SizedBox(height: 16),
            Text(
              settingsController.appName.value ?? 'Sales Management App'.tr,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your store easily and efficiently'.tr,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Developer Info
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Developer'.tr,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Abdulrasol Al-Hilo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.teal),
                      title: const Text('Email'),
                      subtitle: const Text('abdulrsol97@gmail.com'),
                      onTap: () => _launchUrl('mailto:abdulrsol97@gmail.com'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.language, color: Colors.teal),
                      title: const Text('Website'),
                      subtitle: const Text('abdulrasol.github.io'),
                      onTap: () => _launchUrl('https://abdulrasol.github.io/'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.web, color: Colors.teal),
                      title: Text('App Page'.tr),
                      subtitle: const Text('store_managment'),
                      onTap: () => _launchUrl('https://abdulrasol.github.io/#store_managment'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.code, color: Colors.teal),
                      title: const Text('GitHub'),
                      subtitle: const Text('github.com/abdulrasol'),
                      onTap: () => _launchUrl('https://github.com/abdulrasol'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Donation Button
            SizedBox(
              width: double.infinity,
              //  height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Direct link for WhatsApp
                  _launchUrl('https://wa.me/9647813639721');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.volunteer_activism), // Heart in hand icon
                label: Text('Donate (Support via WhatsApp)'.tr),
              ),
            ),

            const SizedBox(height: 40),
            Text(
              '${'Version'.tr} $_version +$_buildNumber',
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
