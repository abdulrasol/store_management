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
    if (invoice.target == null) return 0.0;

    num totalRevenue = 0;
    num totalCost = 0;

    for (var item in invoice.target!.items) {
      // Revenue for this item
      totalRevenue += (item.itemSellPrice * item.quantity);

      // Cost for this item
      // Use historical buy price if available, otherwise current buy price
      double buyPrice = item.itemBuyPrice > 0 ? item.itemBuyPrice : (item.item.target?.buyPrice ?? 0.0);

      totalCost += (buyPrice * item.quantity);
    }

    // Gross Profit
    num gross = totalRevenue - totalCost;

    // Subtract Invoice Discount
    // Discount reduces the profit
    num discount = invoice.target!.discount();

    return gross - discount;
  }
}
