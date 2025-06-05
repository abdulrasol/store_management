import 'package:objectbox/objectbox.dart';
import 'package:store_management/models/item.dart';

@Entity()
class InvoiceItem {
  @Id()
  int id = 0;
  double discount;
  int quantity;
  // معلومات العنصر المنسوخة
  String itemName; // اسم العنصر

  double itemSellPrice; // سعر البيع وقت إنشاء الفاتورة

  // العلاقة يمكن إبقاؤها للمرجعية فقط، لكن لا تعتمد عليها للسعر
  final item = ToOne<Item>();

  InvoiceItem({
    this.discount = 0,
    required this.quantity,
    required this.itemName,
    required this.itemSellPrice,
  });

  double saledPrice() => itemSellPrice;

  // احسب السعر الإجمالي باستخدام البيانات المخزنة بدلاً من العلاقة
  double totalPrice() => (itemSellPrice) * quantity;
  Map<String, dynamic> toMap() {
    return {
      'item': item.target?.toMap(),
      'quantity': quantity,
      'itemName': itemName,
      'itemSellPrice': itemSellPrice,
    };
  }
}
