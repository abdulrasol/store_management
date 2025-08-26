import 'package:path_provider/path_provider.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/expense.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/invoice_item.dart';
import 'package:store_management/models/item.dart';
import 'package:store_management/models/profits.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/models/voucher.dart';
import 'package:store_management/objectbox.g.dart';


class ObjectBox {
  late Store store;
  late Box<Item> itemBox;
  late Box<InvoiceItem> invoiceItemBox;
  late Box<Invoice> invoiceBox;
  late Box<Customer> customerBox;
  late Box<Profits> profitsBox;
  late Box<Transaction> transactionBox;
  late Box<Voucher> voucherBox;
  late Box<Expense> expenseBox;

  ObjectBox._create(this.store) {
    itemBox = Box<Item>(store);
    invoiceItemBox = Box<InvoiceItem>(store);
    profitsBox = Box<Profits>(store);
    customerBox = Box<Customer>(store);
    invoiceBox = Box<Invoice>(store);
    transactionBox = Box<Transaction>(store);
    voucherBox = Box<Voucher>(store);
    expenseBox = Box<Expense>(store);
  }

  static Future<ObjectBox> create() async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: appDocumentsDir.path);
    return ObjectBox._create(store);
  }
}

// void deleteDbFiles() async {
//   Directory docDir = await getApplicationDocumentsDirectory();
//   docDir.deleteSync(recursive: true);
// }
