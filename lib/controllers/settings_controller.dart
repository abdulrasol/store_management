import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  late SharedPreferences prefs;
  late Rx<String?> appName;
  late Rx<String?> logo;
  late NumberFormat currencyFormat;

  @override
  void onInit() async {
    await updateSettings();
    super.onInit();
  }

  Future<void> updateSettings() async {
    prefs = await SharedPreferences.getInstance();

    currencyFormat = NumberFormat.currency(
      name: prefs.getString('currency_name') ?? 'USD',
      symbol: prefs.getString('currency_symbol') ?? '\$',
      decimalDigits: prefs.getInt('decimal_digits') ?? 0,
    );
    appName = prefs.getString('store_name').obs;
    logo = prefs.getString('logo').obs;
  }

  String currencyFormatter(num number) {
    if (number < 0) {
      return '- ${currencyFormat.format(number).split('-')[0]} ${currencyFormat.format(number).split('-')[1]}';
    }

    return currencyFormat.format(number);
  }
}
