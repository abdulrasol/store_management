import 'package:get/get.dart';
import 'package:store_management/database/objectbox.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/expense.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/invoice_item.dart';
import 'package:store_management/models/item.dart';
import 'package:store_management/models/profits.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/models/voucher.dart';
import 'package:store_management/objectbox.g.dart';

class DatabaseController extends GetxController {
  late ObjectBox objectBox;

  RxList<Item> items = <Item>[].obs;
  Future<void> init(ObjectBox store) async {
    objectBox = store;
    loading();
  }

  void loading() {
    loadItems();
    loadCustomers();
    loadInvoices();
    loadTransactions();
    loadProfits();
    loadVouchers();
    loadExpenses();
  }

  // items
  void loadItems() {
    items.value = objectBox.itemBox.getAll();
  }

  int addItem({required Item item}) {
    int id = objectBox.itemBox.put(item);
    loading();
    return id;
  }

  Item? getItemById(int id) {
    return objectBox.itemBox.get(id);
  }

  int updateItem(
    int id, {
    required String name,
    required double sellPrice,
    required double buyPrice,
    required int qunatity,
    required Customer supplier,
  }) {
    var item = Item(
        name: name,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        quantity: qunatity);

    item.supplier.target = supplier;
    item.id = id;
    objectBox.itemBox.put(item);
    loading();
    return id;
  }

  void deleteItem(int id) {
    objectBox.itemBox.remove(id);
    loading();
  }

  // invoices
  RxList<Invoice> inovices = <Invoice>[].obs;
  void loadInvoices() {
    inovices.value = objectBox.invoiceBox.getAll().reversed.toList();
  }

  int createInvoice(Invoice invoice) {
    for (InvoiceItem item in invoice.items) {
      objectBox.invoiceItemBox.put(item);
    }
    int id = objectBox.invoiceBox.put(invoice);

    for (var item in invoice.items) {
      item.item.target!.quantity -= item.quantity.toInt();
      item.item.target!.sellPrice = item.itemSellPrice;
      objectBox.itemBox.put(item.item.target!);
    }
    invoice.items;
    loading();
    return id;
  }

  int updateInvoice({
    required Map<String, Map<String, dynamic>> oldItemsMap,
    required Invoice invoice,
    required double paymentAmount,
    required double discount,
  }) {
    // new and updated items
    for (InvoiceItem invoiceItem in invoice.items) {
      objectBox.invoiceItemBox.put(invoiceItem);
      Map<String, dynamic>? oldItemQuantity = oldItemsMap[invoiceItem.itemName];
      // if item is updated
      if (oldItemQuantity != null) {
        int oldQ = oldItemQuantity['quantity'].toInt();
        int newQ = invoiceItem.quantity;
        int leftQ = oldItemQuantity['total-quantity'].toInt();

        invoiceItem.item.target!.quantity = (leftQ + oldQ) - newQ;

        addItem(item: invoiceItem.item.target!);
      }
      // now add
      else {
        invoiceItem.item.target!.quantity -= invoiceItem.quantity.toInt();
        addItem(item: invoiceItem.item.target!);
      }
    }

    // removed item
    List<String> oldItemsNameList =
        oldItemsMap.keys.toList(); // to loop removed item
    for (int i = 0; i <= oldItemsNameList.length - 1; i++) {
      if (!invoice.items.any((item) => item.itemName == oldItemsNameList[i])) {
        double quantity = oldItemsMap[oldItemsNameList[i]]?['quantity'];
        int id = oldItemsMap[oldItemsNameList[i]]?['id'];
        Item item = getItemById(id)!;
        item.quantity += quantity.toInt();
        addItem(item: item);
      }
    }

    Transaction transactionSell = invoice.transactions[0];
    transactionSell.amount = invoice.pricetoPay();
    Transaction transactionPay = invoice.transactions[1];
    transactionPay.amount = paymentAmount;
    Transaction transactionDiscount =
        Transaction(date: invoice.date, amount: discount);
    try {
      transactionDiscount = invoice.transactions[2];
    } catch (e) {
      transactionDiscount.customer.target = invoice.customer.target;
      invoice.transactions.add(transactionDiscount);
      print(' old version without discount transacrion');
    }
    transactionDiscount.amount = discount;
    int id = objectBox.invoiceBox.put(invoice);
    objectBox.transactionBox
        .putMany([transactionSell, transactionPay, transactionDiscount]);

    loading();
    return id;
  }

  Invoice? getInvoiceById(int id) {
    return objectBox.invoiceBox.get(id);
  }

  bool removeInvoice(int id) {
    for (InvoiceItem invoiceItem in objectBox.invoiceBox.get(id)!.items) {
      Item item = objectBox.itemBox.get(invoiceItem.item.targetId)!;
      item.quantity += invoiceItem.quantity.toInt();
      objectBox.itemBox.put(item);
      //  objectBox.itemBox.put(objectBox.itemBox
      //      .get(objectBox.itemBox.get(t.item.targetId)!.qunatity += t.quantity.toInt()!)!);
    }
    for (var t in objectBox.invoiceBox.get(id)!.transactions) {
      objectBox.transactionBox.remove(t.id);
    }

    bool delete = objectBox.invoiceBox.remove(id);
    loading();
    return delete;
  }

// Voucger
  RxList<Voucher> vouchers = <Voucher>[].obs;
  void loadVouchers() {
    vouchers.value = objectBox.voucherBox.getAll().reversed.toList();
  }

  int createVouchers(Voucher voucher) {
    int id = objectBox.voucherBox.put(voucher);
    for (var item in voucher.items) {
      objectBox.itemBox.put(item);
    }

    loading();
    return id;
  }

  Voucher? getVoucherById(int id) {
    return objectBox.voucherBox.get(id);
  }

  // customers
  RxList<Customer> custormers = <Customer>[].obs;
  RxList<Customer> suppliers = <Customer>[].obs;

  void loadCustomers() {
    custormers.value = objectBox.customerBox
        .query(Customer_.customerType.equals(0))
        .build()
        .find();
    suppliers.value = objectBox.customerBox
        .query(Customer_.customerType.equals(1))
        .build()
        .find();
  }

  int addCustomer(Customer customer) {
    int id = objectBox.customerBox.put(customer);
    loading();
    return id;
  }

  num customerDebt() {
    return custormers.where((customer) => customer.balance() > 0).toList().fold(
        0, (num previousValue, element) => previousValue + element.balance());
  }

  // Transactions
  RxList<Transaction> customersTransactions = <Transaction>[].obs;
  RxList<Transaction> sellTransaction = <Transaction>[].obs;
  RxList<Transaction> payTransaction = <Transaction>[].obs;

  RxList<Transaction> discountTransactions = <Transaction>[].obs;

  void loadTransactions() {
    customersTransactions.value = objectBox.transactionBox
        .getAll()
        .where((trans) => trans.customer.target!.customerType == 0)
        .toList()
        .reversed
        .toList();
    discountTransactions.value = objectBox.transactionBox
        .getAll()
        .where((trans) => trans.customer.target!.customerType == 1)
        .toList();
    Query query = databaseController.objectBox.transactionBox
        .query(Transaction_.amount.lessThan(0))
        .build();
    sellTransaction.value = query
        .find()
        .where((trans) => trans.customer.target! is Customer)
        .toList() as List<Transaction>;
    payTransaction.value = databaseController.objectBox.transactionBox
        .query(Transaction_.amount.greaterThan(0))
        .order(Transaction_.date, flags: Order.descending)
        .build()
        .find();
  }

  List<Transaction> customerPaymetTranscation() =>
      customersTransactions.where((trans) => trans.amount > 0).toList();
  List<Transaction> supplierPaymetTranscation() =>
      discountTransactions.where((trans) => trans.amount > 0).toList();

  int newTransaction(Transaction transaction) {
    int id = objectBox.transactionBox.put(transaction);
    loading();
    return id;
  }

  // profits
  RxList<Profits> profits = <Profits>[].obs;
  void loadProfits() {
    List<Profits> list = objectBox.profitsBox.getAll();
    for (Profits p in list) {
      if (p.invoice.target == null) {
        objectBox.profitsBox.remove(p.id);
      }
    }
    profits.value = objectBox.profitsBox.getAll();
  }

  // credits
  num credits() {
    num value = customersTransactions
        .where((trans) => trans.customer.target!.customerType == 1)
        .fold<double>(0, (sum, trans) => sum + trans.amount);
    return value;
  }

  // debits
  num debits() {
    num value = customersTransactions
        .where((trans) => trans.customer.target!.customerType == 0)
        .fold<double>(0, (sum, trans) => sum + trans.amount);
    return value;
  }

  int generateProfit(Profits profit) {
    int id = objectBox.profitsBox.put(profit);
    loading();
    return id;
  }

// Expense
  RxList<Expense> expenses = <Expense>[].obs;
  void loadExpenses() {
    expenses.value = objectBox.expenseBox.getAll();
  }

  int addExpense(Expense expense) {
    int id = objectBox.expenseBox.put(expense);
    loading();
    return id;
  }

  List<Expense> getFilteriedExpenses(DateTime fromDate) {
    return expenses.where((expense) => expense.date.isAfter(fromDate)).toList();
  }

  num netRevenue() {
    num profits = databaseController.profits.fold(
        0, (num previousValue, element) => previousValue + element.profit());
    num expenses = databaseController.expenses.fold(
        0, (num previousValue, element) => previousValue + element.amount);
    return profits - expenses;
  }

  void deleteInvoice(Invoice invoice) {
    List<Transaction> trans = invoice.transactions;
    List<InvoiceItem> items = invoice.items;

    for (InvoiceItem item in items) {
      item.item.target!.quantity += item.quantity;
      objectBox.itemBox.put(item.item.target!);
      objectBox.invoiceItemBox.remove(item.id);
    }
    for (Transaction tran in trans) {
      objectBox.transactionBox.remove(tran.id);
    }
    objectBox.invoiceBox.remove(invoice.id);
  }
}
