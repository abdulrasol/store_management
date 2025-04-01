import 'package:objectbox/objectbox.dart';
import 'package:store_management/models/item.dart';

@Entity()
class VoucherItem {
  @Id()
  int id = 0;
  double discount;
  int quantity;
  // معلومات العنصر المنسوخة
  String itemName; // اسم العنصر

  double itemSellPrice; // سعر البيع وقت إنشاء الفاتورة

  // العلاقة يمكن إبقاؤها للمرجعية فقط، لكن لا تعتمد عليها للسعر
  final item = ToOne<Item>();

  VoucherItem({
    this.discount = 0,
    required this.quantity,
    required this.itemName,
    required this.itemSellPrice,
  });

  // احسب السعر الإجمالي باستخدام البيانات المخزنة بدلاً من العلاقة
  double totalPrice() => (itemSellPrice - discount) * quantity;
}
