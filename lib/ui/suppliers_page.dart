import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/ui/customer_view.dart';
import 'package:store_management/ui/supplier_add.dart';
import 'package:store_management/ui/transactions_page.dart';
import 'package:store_management/utils/app_constants.dart';

DatabaseController databaseController = Get.find();

class SupplierPage extends StatelessWidget {
  const SupplierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Suppliers'),
          actions: [
            IconButton(
              onPressed: () {
                showSearch(context: context, delegate: Search());
              },
              icon: Icon(Icons.search),
            ),
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text('Suppliers'), horSpace, Icon(Icons.support)],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Payment'),
                    horSpace,
                    Icon(Icons.payment_sharp)
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(children: [
          Obx(
            () => ListView.builder(
                itemCount: databaseController.suppliers().length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                        'Suppliers name: ${databaseController.suppliers[index].name}'),
                    subtitle: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runAlignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        Text(
                            'Phone: ${databaseController.suppliers[index].phone}'),
                        Text(
                            'invoices: ${databaseController.suppliers()[index].invoices.length}'),
                        Text(
                            'transactions: ${databaseController.suppliers()[index].trasnsactions.length}'),
                      ],
                    ),
                    onTap: () => Get.to(
                      () => CustomerView(
                        customer: databaseController.suppliers[index],
                      ),
                    ),
                  );
                }),
          ),
          transactionsView(databaseController.supplierTransactions),
        ]),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Get.to(() => SupplierAdd());
            },
            child: Icon(Icons.add)),
      ),
    );
  }
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
    List<Customer> suppliers = databaseController.suppliers
        .where((custormer) =>
            custormer.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
              'Customer name: ${databaseController.suppliers[index].name}'),
          subtitle: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Text('Phone: ${databaseController.suppliers[index].phone}'),
              Text(
                  'invoices: ${databaseController.suppliers()[index].invoices.length}'),
              Text(
                  'transactions: ${databaseController.suppliers()[index].trasnsactions.length}'),
              Text('Phone: ${databaseController.suppliers[index].type()}')
            ],
          ),
          onTap: () => Get.to(
            () => CustomerView(
              customer: databaseController.suppliers[index],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Customer> suppliers = databaseController.suppliers
        .where((customer) =>
            customer.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
              'Customer name: ${databaseController.suppliers[index].name}'),
          subtitle: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Text('Phone: ${databaseController.suppliers[index].phone}'),
              Text(
                  'invoices: ${databaseController.suppliers()[index].invoices.length}'),
              Text(
                  'transactions: ${databaseController.suppliers()[index].trasnsactions.length}'),
            ],
          ),
          onTap: () => Get.to(
            () => CustomerView(
              customer: databaseController.suppliers[index],
            ),
          ),
        );
      },
    );
  }
}
