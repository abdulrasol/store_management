import 'package:get/get.dart';
import 'package:store_management/utils/translations/ar.dart';
import 'package:store_management/utils/translations/en.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': en,
        'ar': ar,
      };
}
