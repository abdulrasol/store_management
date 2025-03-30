import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/item.dart';
import 'transaction.dart';

DatabaseController databaseController = Get.find();
SettingsController settingsController = Get.find();

@Entity()
class Voucher {
  @Id()
  int id = 0;
  @Backlink('voucher')
  final transactions = ToMany<Transaction>();
  @Property(type: PropertyType.date)
  late DateTime date;
  final items = ToMany<Item>();
  final customer = ToOne<Customer>();

  Voucher() {
    date = DateTime.now();
  }
  double price() {
    double price = 0.0; // إعادة تعيين السعر قبل الحساب
    for (var item in items) {
      price += (item.buyPrice) * item.quantity;
    }
    return price;
  }

  // double left() => pricetoPay() - (transaction.target!.amount);
  String voucherDate() {
    List s = date.toLocal().toIso8601String().split('T');
    return '${s[0].substring(0, 10)} ${s[1].substring(0, 5)}';
  }

  String voucherNumber() {
    return '${date.month}${date.day}-$id';
  }

  num balance() {
    final List<num> transactionAmount = databaseController.customersTransactions
        .where((transaction) =>
            transaction.customer.targetId == customer.target!.id)
        .map((t) => t.amount)
        .toList();

    num balance = transactionAmount.fold<num>(
        0, (previousValue, transaction) => previousValue + transaction);

    return balance;
  }
}
