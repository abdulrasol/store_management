import 'package:objectbox/objectbox.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/invoice_item.dart';

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

    if (invoice.target != null) {
      for (InvoiceItem invoiceItem in invoice.target!.items) {
        total += ((invoiceItem.itemSellPrice - invoiceItem.discount) -
                invoiceItem.item.target!.buyPrice) *
            invoiceItem.quantity;
      }
      return total;
    }

    return 0.0;
  }
}
