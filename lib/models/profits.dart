import 'package:objectbox/objectbox.dart';
import 'package:store_management/models/invoice.dart';


@Entity()
class Profits {
  @Id()
  int id = 0;
  int date = 0;

  final invoice = ToOne<Invoice>();

  Profits() {
    date = DateTime.now().millisecondsSinceEpoch;
  }
//trasnsactions.fold<double>(0, (sum, trans) => sum + trans.amount)
  num profit() {
    num total = 0;
    num discount = 0;

    if (invoice.target != null) {
      total = invoice.target!.items.fold(
          0,
          (sum, item) =>
              sum + (item.itemSellPrice - item.item.target!.buyPrice));

      if (invoice.target!.transactions.length == 3) {
        discount = invoice.target!.transactions[2].amount;
      }
      return total - discount;
    }

    return 0.0;
  }
}
