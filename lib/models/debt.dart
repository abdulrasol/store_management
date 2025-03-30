import 'package:objectbox/objectbox.dart';
import 'package:store_management/models/customer.dart';

class Debt {
  @Id()
  int id = 0;
  double amount = 0;
  final customer = ToOne<Customer>();
}
