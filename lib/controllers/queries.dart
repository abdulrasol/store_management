// customers
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/database/objectbox.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/objectbox.g.dart';

import '../models/customer.dart';

class Queries {
  DatabaseController databaseController = Get.find();
  ObjectBox? objectBox;

// transactions

  List<Transaction> sellTransactionQuery() {
    Query<Transaction> query = databaseController.objectBox.transactionBox
        .query(Transaction_.amount.lessThan(0))
        .build();
    final transaction = query.find();
    query.close();
    return transaction;
  }

  List<Transaction> payTransactionQuery() {
    Query<Transaction> query = databaseController.objectBox.transactionBox
        .query(Transaction_.amount.greaterThan(0))
        .order(Transaction_.date, flags: Order.descending)
        .build();
    final transaction = query.find();
    query.close();
    return transaction;
  }

  List<Transaction> costumerPayTransactionQuery(Customer customer) {
    Query<Transaction> query = databaseController.objectBox.transactionBox
        .query(Transaction_.amount.greaterThan(0))
        .order(Transaction_.date, flags: Order.descending)
        .build();
    final transaction = query.find();
    query.close();
    return transaction;
  }

  // Customers

  // invoices
  void customers(Customer customer) async {
//     Query<User> query = userBox.query(User_.firstName.equals('Joe')).build();
// List<User> joes = query.find();
// query.close();
    // objectBox = await ObjectBox.create();
    // Query<Invoice> query = objectBox!.invoiceBox
    //     .query(Invoice_.customer, )
    //     .build();
  }
}
