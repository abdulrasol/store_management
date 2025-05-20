import 'package:objectbox/objectbox.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/invoice_item.dart';
import 'transaction.dart';

@Entity()
class Invoice {
  @Id()
  int id = 0;
  @Backlink('invoice')
  final transactions = ToMany<Transaction>();
  late int date;
  final items = ToMany<InvoiceItem>();
  final customer = ToOne<Customer>();
  //late double totalPrice;

  Invoice() {
    date = DateTime.now().millisecondsSinceEpoch;
  }
  double price() {
    double price = 0.0; // إعادة تعيين السعر قبل الحساب
    for (var item in items) {
      price += (item.saledPrice()) * item.quantity;
    }
    return price + discount();
  }

  double pricetoPay() {
    double pricetoPay = 0.0; // إعادة تعيين السعر قبل الحساب
    for (var item in items) {
      pricetoPay += item.totalPrice();
    }
    return pricetoPay;
  }

  double discount() {
    double discount = 0.0; // إعادة تعيين السعر قبل الحساب
    for (var item in items) {
      discount += item.discount;
    }
    return discount;
  }

  // double left() => pricetoPay() - (transaction.target!.amount);
  String invoiceDate() {
    List s = DateTime.fromMillisecondsSinceEpoch(date)
        .toLocal()
        .toIso8601String()
        .split('T');
    return '${s[0].substring(0, 10)} ${s[1].substring(0, 5)}';
  }

  String invoiceNumber() {
    return '${date.toString().substring((date.toString().length) - 4, date.toString().length)}-$id';
  }
}
