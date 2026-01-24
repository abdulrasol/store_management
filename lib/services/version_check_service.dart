import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:new_version_plus/new_version_plus.dart';

class VersionCheckService {
  final NewVersionPlus _newVersion = NewVersionPlus();

  Future<void> checkVersion(BuildContext context) async {
    try {
      final status = await _newVersion.getVersionStatus();
      debugPrint('checkVersion appStoreLink  ${status?.appStoreLink}');
      debugPrint('checkVersion releaseNotes ${status?.releaseNotes}');
      debugPrint('checkVersion localVersion ${status?.localVersion}');
      debugPrint('checkVersion storeVersion ${status?.storeVersion}');
      debugPrint('checkVersion canUpdate ${status?.canUpdate.toString()}');
      if (status != null && status.canUpdate) {
        if (context.mounted) {
          _newVersion.showUpdateDialog(
            context: context,
            versionStatus: status,
            dialogTitle: 'Update Available'.tr,
            dialogText: '${'A new version of the app is available: '.tr}${status.storeVersion}\n${'Please update to enjoy the latest features.'.tr}',
            updateButtonText: 'Update Now'.tr,
            dismissButtonText: 'Maybe Later'.tr,
            dismissAction: () {
              // User dismissed the dialog, do nothing (not forced)
              Get.back();
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking version: $e');
    }
  }
}
