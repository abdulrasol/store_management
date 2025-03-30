import 'package:objectbox/objectbox.dart';
import 'package:store_management/models/profits.dart';

@Entity()
class Expense {
  @Id()
  int id = 0;
  String description;
  double amount;
  @Property(type: PropertyType.date)
  DateTime date;

  final profit = ToOne<Profits>();
  Expense(
      {required this.description, required this.date, required this.amount});

  String getDate() {
    List s = date.toLocal().toIso8601String().split('T');
    return '${s[0].substring(0, 10)}, ${s[1].substring(0, 5)}';
  }
}
