import 'package:objectbox/objectbox.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/item.dart';

import 'transaction.dart';

@Entity()
class Customer {
  @Id()
  int id = 0;
  String name;
  String phone;
  int customerType;
  @Backlink('supplier')
  final items = ToMany<Item>();

  @Backlink('customer')
  final trasnsactions = ToMany<Transaction>();

  @Backlink('customer')
  final invoices = ToMany<Invoice>();

  Customer({required this.name, required this.phone, this.customerType = 0});

  double balance() {
    return trasnsactions.fold<double>(0, (sum, trans) => sum + trans.amount);
  }

  String type() {
    if (customerType == 0) {
      return 'Customer';
    } else {
      return 'Supplier';
    }
  }
}
