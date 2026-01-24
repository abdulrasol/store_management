import 'package:get/get.dart';
import 'package:store_management/utils/translations/ar.dart';
import 'package:store_management/utils/translations/de.dart';
import 'package:store_management/utils/translations/en.dart';
import 'package:store_management/utils/translations/es.dart';
import 'package:store_management/utils/translations/fa.dart';
import 'package:store_management/utils/translations/fr.dart';
import 'package:store_management/utils/translations/hi.dart';
import 'package:store_management/utils/translations/id.dart';
import 'package:store_management/utils/translations/it.dart';
import 'package:store_management/utils/translations/pl.dart';
import 'package:store_management/utils/translations/pt.dart';
import 'package:store_management/utils/translations/ro.dart';
import 'package:store_management/utils/translations/ru.dart';
import 'package:store_management/utils/translations/th.dart';
import 'package:store_management/utils/translations/tr.dart';
import 'package:store_management/utils/translations/zh.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': en,
        'ar': ar,
        'fa': fa,
        'tr': tr,
        'zh': zh,
        'es': es,
        'fr': fr,
        'de': de,
        'ru': ru,
        'pt': pt,
        'hi': hi,
        'id': id,
        'it': it,
        'th': th,
        'pl': pl,
        'ro': ro,
      };
}
