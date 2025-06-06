import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/voucher.dart';

@Entity()
class Transaction {
  @Id()
  int id = 0;
  double amount;
  final invoice = ToOne<Invoice>();
  final voucher = ToOne<Voucher>();
  final customer = ToOne<Customer>();
  int date;

  Transaction({
    required this.date,
    required this.amount,
  });

  String paymentDate() {
    List s = DateTime.fromMillisecondsSinceEpoch(date)
        .toLocal()
        .toIso8601String()
        .split('T');
    return '${s[0].substring(0, 10)}, ${s[1].substring(0, 5)}';
  }

  TransactionType type() {
    if (amount < 0) {
      return TransactionType.buy;
    } else {
      return TransactionType.pay;
    }
  }

  String stringType() {
    switch (amount) {
      case < 0:
        return 'inovice'.tr;
      case > 0:
        try {
          if (amount == invoice.target!.discount()) {
            return 'discount-tran'.tr;
          }
        } catch (e) {
          return 'payment'.tr;
        }
        return 'payment'.tr;
      default:
        return 'info';
    }
    // if (amount > 0) {
    //   try {
    //     if (amount == invoice.target!.discount()) {
    //       return 'discount'.tr;
    //     }
    //   } catch (e) {
    //     print('test');
    //   }
    // } else {}
  }

  String transactionNumber() {
    return '${date.toString().substring((date.toString().length) - 4, date.toString().length)}-$id';
  }

  // Transaction? totalDebits() {
  //   return customer.target?.customerType == 0 ? this : null;
  // }
}

enum TransactionType { buy, pay, discount }
