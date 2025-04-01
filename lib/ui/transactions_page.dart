import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/ui/transaction_view.dart';

DatabaseController databaseController = Get.find();
SettingsController settingsController = Get.find();

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<Transaction> transactions = databaseController.customersTransactions;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'.tr),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                transactions = databaseController.customersTransactions;
              });
            },
            child: Text('All'.tr),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                transactions = databaseController.customerPaymetTranscation();
              });
            },
            child: Text('Payments'.tr),
          ),
          IconButton(
            onPressed: () {
              showSearch(context: context, delegate: Search());
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: Obx(
        () => transactionsView(transactions),
      ),
    );
  }
}

Widget transactionsView(List<Transaction> transactions) {
  return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('${transactions[index].customer.target?.name}',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Text(
                  '${'Amount'.tr}: ${settingsController.currencyFormatter(transactions[index].amount)}'),
              Text(
                  '${'Transaction Number'.tr}: ${transactions[index].transactionNumber()}'),
              Text(transactions[index].paymentDate()),
            ],
          ),
          onTap: () {
            Get.to(() => TransactionView(transaction: transactions[index]));
          },
        );
      });
}

class Search extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Transaction> transactions = databaseController.customersTransactions
        .where((tra) => tra.transactionNumber().contains(query))
        .toList();
    return searchResultBuilder(transactions);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Transaction> transactions = databaseController.customersTransactions
        .where((tra) => tra.transactionNumber().contains(query))
        .toList();
    return searchResultBuilder(transactions);
  }

  ListView searchResultBuilder(List<Transaction> transactions) {
    return ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('${transactions[index].customer.target?.name}'),
            subtitle: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Text(
                    '${'Amount'.tr}: ${settingsController.currencyFormatter(transactions[index].amount)}'),
                Text(
                    '${'Transaction Number'.tr}: ${transactions[index].transactionNumber()}'),
                Text(transactions[index].paymentDate()),
              ],
            ),
            onTap: () {
              Get.to(() => TransactionView(transaction: transactions[index]));
            },
          );
        });
  }
}
