import 'package:objectbox/objectbox.dart';
import 'package:store_management/models/customer.dart';

@Entity()
class Item {
  @Id()
  int id = 0;
  String name;

  final supplier = ToOne<Customer>();
  double buyPrice;
  double sellPrice;
  int quantity;

  Item({
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
  });

  bool availabllty() => quantity > 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'supplier': supplier.target?.name,
        'buyprice': buyPrice,
        'sellprice': sellPrice,
        'qunatity': quantity,
        'code': code(),
      };

  String code() {
    return '$id-$name';
  }
}
