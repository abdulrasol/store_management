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

  // Expose the store so other controllers can use it
  ObjectBox get db => objectBox;

  Future<void> init() async {
    objectBox = await ObjectBox.create();
    loading();
    //print("Database Initialized");
  }

  RxList<Item> items = <Item>[].obs;

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
    var item = Item(name: name, buyPrice: buyPrice, sellPrice: sellPrice, quantity: qunatity);

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
      // Set buy price snapshot if not already set (e.g. from UI)
      if (item.itemBuyPrice == 0 && item.item.target != null) {
        item.itemBuyPrice = item.item.target!.buyPrice;
      }
      objectBox.invoiceItemBox.put(item);
    }
    int id = objectBox.invoiceBox.put(invoice);

    // Explicitly save transactions to ensure they are persisted
    // The invoice.transactions list should already contain the new transactions
    if (invoice.transactions.isNotEmpty) {
      objectBox.transactionBox.putMany(invoice.transactions);
    }

    for (var item in invoice.items) {
      if (item.item.target != null) {
        item.item.target!.quantity -= item.quantity.toInt();
        item.item.target!.sellPrice = item.itemSellPrice;
        objectBox.itemBox.put(item.item.target!);
      }
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
      if (invoiceItem.itemBuyPrice == 0 && invoiceItem.item.target != null) {
        invoiceItem.itemBuyPrice = invoiceItem.item.target!.buyPrice;
      }
      objectBox.invoiceItemBox.put(invoiceItem);
      Map<String, dynamic>? oldItemQuantity = oldItemsMap[invoiceItem.itemName];
      // if item is updated
      if (oldItemQuantity != null) {
        int oldQ = oldItemQuantity['quantity'].toInt();
        int newQ = invoiceItem.quantity;
        int leftQ = oldItemQuantity['total-quantity'].toInt();

        // Only update stock if linked to a real item
        if (invoiceItem.item.target != null) {
          invoiceItem.item.target!.quantity = (leftQ + oldQ) - newQ;
          addItem(item: invoiceItem.item.target!);
        }
      }
      // now add
      else {
        if (invoiceItem.item.target != null) {
          invoiceItem.item.target!.quantity -= invoiceItem.quantity.toInt();
          addItem(item: invoiceItem.item.target!);
        }
      }
    }

    // removed item
    List<String> oldItemsNameList = oldItemsMap.keys.toList(); // to loop removed item
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
    transactionSell.amount = -1 * invoice.pricetoPay();
    Transaction transactionPay = invoice.transactions[1];
    transactionPay.amount = paymentAmount;
    Transaction transactionDiscount = Transaction(date: invoice.date, amount: discount, type: 3);
    try {
      transactionDiscount = invoice.transactions[2];
    } catch (e) {
      transactionDiscount.customer.target = invoice.customer.target;
      invoice.transactions.add(transactionDiscount);
      // print(' old version without discount transacrion');
    }
    transactionDiscount.amount = discount;
    int id = objectBox.invoiceBox.put(invoice);
    objectBox.transactionBox.putMany([transactionSell, transactionPay, transactionDiscount]);

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
    custormers.value = objectBox.customerBox.query(Customer_.customerType.equals(0)).build().find();
    suppliers.value = objectBox.customerBox.query(Customer_.customerType.equals(1)).build().find();
  }

  int addCustomer(Customer customer) {
    int id = objectBox.customerBox.put(customer);
    loading();
    return id;
  }

  num customerDebt() {
    return custormers.where((customer) => customer.balance() < 0).toList().fold(0, (num previousValue, element) => previousValue + element.balance());
  }

  List<Customer> getDebtors() {
    return custormers.where((customer) => customer.balance() < 0).toList();
  }

  // Transactions
  RxList<Transaction> customersTransactions = <Transaction>[].obs;
  RxList<Transaction> sellTransaction = <Transaction>[].obs;
  RxList<Transaction> payTransaction = <Transaction>[].obs;

  RxList<Transaction> discountTransactions = <Transaction>[].obs;

  void loadTransactions() {
    customersTransactions.value = objectBox.transactionBox.getAll().where((trans) => trans.customer.target!.customerType == 0).toList().reversed.toList();
    discountTransactions.value = objectBox.transactionBox.getAll().where((trans) => trans.customer.target!.customerType == 1).toList();
    Query query = databaseController.objectBox.transactionBox.query(Transaction_.amount.lessThan(0)).build();
    sellTransaction.value = query.find().where((trans) => trans.customer.target! is Customer).toList() as List<Transaction>;
    payTransaction.value =
        databaseController.objectBox.transactionBox.query(Transaction_.amount.greaterThan(0)).order(Transaction_.date, flags: Order.descending).build().find();
  }

  List<Transaction> customerPaymetTranscation() => customersTransactions.where((trans) => trans.amount > 0).toList();
  List<Transaction> supplierPaymetTranscation() => discountTransactions.where((trans) => trans.amount > 0).toList();

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
    num value = customersTransactions.where((trans) => trans.customer.target!.customerType == 1).fold<double>(0, (sum, trans) => sum + trans.amount);
    return value;
  }

  // debits
  num debits() {
    num value = customersTransactions.where((trans) => trans.customer.target!.customerType == 0).fold<double>(0, (sum, trans) => sum + trans.amount);
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
    num profits = databaseController.profits.fold(0, (num previousValue, element) => previousValue + element.profit());
    num expenses = databaseController.expenses.fold(0, (num previousValue, element) => previousValue + element.amount);
    return profits - expenses;
  }

  void deleteInvoice(Invoice invoice) {
    List<Transaction> trans = invoice.transactions;
    List<InvoiceItem> items = invoice.items;

    for (InvoiceItem item in items) {
      if (item.item.target != null) {
        item.item.target!.quantity += item.quantity;
        objectBox.itemBox.put(item.item.target!);
      }
      objectBox.invoiceItemBox.remove(item.id);
    }
    for (Transaction tran in trans) {
      objectBox.transactionBox.remove(tran.id);
    }
    objectBox.invoiceBox.remove(invoice.id);
  }

  // --- Analytics & Insights ---

  // --- Analytics & Insights ---

  // Get total sales for the last 7 days
  Map<DateTime, double> getWeeklySales() {
    Map<DateTime, double> sales = {};
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      DateTime startOfDay = DateTime(day.year, day.month, day.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      int startMillis = startOfDay.millisecondsSinceEpoch;
      int endMillis = endOfDay.millisecondsSinceEpoch;

      double dayTotal = inovices.where((inv) => inv.date >= startMillis && inv.date < endMillis).fold(0.0, (sum, inv) => sum + inv.pricetoPay());

      sales[startOfDay] = dayTotal;
    }
    return sales;
  }

  // Get total sales for the last 30 days
  Map<DateTime, double> getMonthlySales() {
    Map<DateTime, double> sales = {};
    DateTime now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      DateTime startOfDay = DateTime(day.year, day.month, day.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      int startMillis = startOfDay.millisecondsSinceEpoch;
      int endMillis = endOfDay.millisecondsSinceEpoch;

      double dayTotal = inovices.where((inv) => inv.date >= startMillis && inv.date < endMillis).fold(0.0, (sum, inv) => sum + inv.pricetoPay());

      sales[startOfDay] = dayTotal;
    }
    return sales;
  }

  // Get total sales for the last 12 months (Yearly view)
  Map<DateTime, double> getYearlySales() {
    Map<DateTime, double> sales = {};
    DateTime now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      DateTime monthDate = DateTime(now.year, now.month - i, 1);
      DateTime nextMonthDate = DateTime(now.year, now.month - i + 1, 1);

      int startMillis = monthDate.millisecondsSinceEpoch;
      int endMillis = nextMonthDate.millisecondsSinceEpoch;

      double monthTotal = inovices.where((inv) => inv.date >= startMillis && inv.date < endMillis).fold(0.0, (sum, inv) => sum + inv.pricetoPay());

      sales[monthDate] = monthTotal;
    }
    return sales;
  }

  // Kept for compatibility if needed, but getYearlySales covers the trend.
  // Renaming/Refactoring existing usage implies we should use getYearlySales instead.
  // But let's keep a generic "All Time" aggregation if user wants specifically that.
  Map<DateTime, double> getAllTimeSales() {
    Map<DateTime, double> sales = {};
    for (var invoice in inovices) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(invoice.date);
      DateTime monthStart = DateTime(date.year, date.month, 1);
      sales[monthStart] = (sales[monthStart] ?? 0) + invoice.pricetoPay();
    }
    var sortedKeys = sales.keys.toList()..sort();
    return {for (var key in sortedKeys) key: sales[key]!};
  }

  // Get top 5 selling items
  List<Map<String, dynamic>> getTopSellingItems() {
    Map<String, int> itemCounts = {};

    // Iterate through all invoices to count item sales
    // Note: optimization for large datasets would require a more direct query or caching
    for (var invoice in inovices) {
      for (var item in invoice.items) {
        itemCounts[item.itemName] = (itemCounts[item.itemName] ?? 0) + item.quantity;
      }
    }

    var sortedEntries = itemCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(5).map((e) => {'name': e.key, 'count': e.value}).toList();
  }

  // --- Consolidated Analytics ---

  double getSales(DateTime start, DateTime end) {
    int startMillis = start.millisecondsSinceEpoch;
    int endMillis = end.millisecondsSinceEpoch;
    return inovices.where((inv) => inv.date >= startMillis && inv.date < endMillis).fold(0.0, (sum, inv) => sum + inv.pricetoPay());
  }

  double getExpenses(DateTime start, DateTime end) {
    // Expense model has 'date' as DateTime? Or int?
    // Let's check Expense model first. Assuming it matches.
    // Actually need to check Expense model definition.
    // expenses list is available.
    return expenses.where((exp) => exp.date.isAfter(start) && exp.date.isBefore(end)).fold(0.0, (sum, exp) => sum + exp.amount);
  }

  double getProfit(DateTime start, DateTime end) {
    return getProfitForPeriod(start, end);
  }

  double getNetRevenue(DateTime start, DateTime end) {
    return getProfit(start, end) - getExpenses(start, end);
  }

  // --- Profit Analytics Helper (Deprecated specific getters if we use dynamic range in UI) ---

  double getProfitForPeriod(DateTime start, DateTime end) {
    int startMillis = start.millisecondsSinceEpoch;
    int endMillis = end.millisecondsSinceEpoch;
    return profits.where((p) => p.date >= startMillis && p.date < endMillis).fold(0.0, (sum, p) => sum + p.profit());
  }

  // Deprecating specific getters in favor of UI driving the range
  // double getTodayProfit()...
  // double getWeeklyProfit()...
  // double getMonthlyProfit()...
  // double getYearlyProfit()...

  double getTodayProfit() {
    DateTime now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day);
    DateTime end = start.add(const Duration(days: 1));
    return getProfitForPeriod(start, end);
  }

  double getWeeklyProfit() {
    DateTime now = DateTime.now();
    // Last 7 days
    return getProfitForPeriod(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)), DateTime.now().add(const Duration(days: 1)));
  }

  double getMonthlyProfit() {
    DateTime now = DateTime.now();
    // Last 30 days
    return getProfitForPeriod(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29)), DateTime.now().add(const Duration(days: 1)));
  }

  double getYearlyProfit() {
    DateTime now = DateTime.now();
    // This Year? Or last 12 months? "Year" usually implies "This Year" or "Last 365 days".
    // I'll do "This Year" (Jan 1 to Now).
    // Or match getYearlySales which is last 12 months.
    // Let's do This Year (Jan 1).
    DateTime start = DateTime(now.year, 1, 1);
    return getProfitForPeriod(start, now.add(const Duration(days: 1)));
  }

  // --- Historical Data For Charts ---

  // Profits
  Map<DateTime, double> getWeeklyProfits() {
    Map<DateTime, double> sales = {};
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      DateTime startOfDay = DateTime(day.year, day.month, day.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));
      sales[startOfDay] = getProfitForPeriod(startOfDay, endOfDay);
    }
    return sales;
  }

  Map<DateTime, double> getMonthlyProfits() {
    Map<DateTime, double> sales = {};
    DateTime now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      DateTime startOfDay = DateTime(day.year, day.month, day.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));
      sales[startOfDay] = getProfitForPeriod(startOfDay, endOfDay);
    }
    return sales;
  }

  Map<DateTime, double> getYearlyProfits() {
    Map<DateTime, double> sales = {};
    DateTime now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      DateTime monthDate = DateTime(now.year, now.month - i, 1);
      DateTime nextMonthDate = DateTime(now.year, now.month - i + 1, 1);
      sales[monthDate] = getProfitForPeriod(monthDate, nextMonthDate);
    }
    return sales;
  }

  // Expenses
  Map<DateTime, double> getWeeklyExpenses() {
    Map<DateTime, double> sales = {};
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      DateTime startOfDay = DateTime(day.year, day.month, day.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));
      sales[startOfDay] = getExpenses(startOfDay, endOfDay);
    }
    return sales;
  }

  Map<DateTime, double> getMonthlyExpenses() {
    Map<DateTime, double> sales = {};
    DateTime now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      DateTime startOfDay = DateTime(day.year, day.month, day.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));
      sales[startOfDay] = getExpenses(startOfDay, endOfDay);
    }
    return sales;
  }

  Map<DateTime, double> getYearlyExpenses() {
    Map<DateTime, double> sales = {};
    DateTime now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      DateTime monthDate = DateTime(now.year, now.month - i, 1);
      DateTime nextMonthDate = DateTime(now.year, now.month - i + 1, 1);
      sales[monthDate] = getExpenses(monthDate, nextMonthDate);
    }
    return sales;
  }

  // Get low stock items (quantity < 5)
  List<Item> getLowStockItems() {
    return items.where((item) => item.quantity < 5).toList();
  }

  // Fix Database Transactions (Utility)
  void fixDatabaseTransactions() {
    // debugPrint("Starting Database Fix...");
    int fixedCount = 0;
    for (var invoice in inovices) {
      // Check if invoice has a valid Sell transaction (Type 1)
      bool hasSellTransaction = false;
      try {
        hasSellTransaction = invoice.transactions.any((t) => t.type == 1);
      } catch (e) {
        hasSellTransaction = false;
      }

      if (!hasSellTransaction) {
        // print("Fixing Invoice ID: ${invoice.id}");
        // Create missing Sell Transaction
        Transaction transactionSell = Transaction(
          amount: -1 * invoice.pricetoPay(),
          date: invoice.date,
          type: 1, // Sell
        );
        transactionSell.invoice.target = invoice;
        transactionSell.customer.target = invoice.customer.target;

        objectBox.transactionBox.put(transactionSell);
        fixedCount++;
      }
    }
    // print("Database Fix Complete. Fixed $fixedCount invoices.");
    if (fixedCount > 0) {
      loading();
      Get.snackbar("Success", "Fixed $fixedCount missing transactions.");
    } else {
      Get.snackbar("Info", "Database is already clean.");
    }
  }
}
