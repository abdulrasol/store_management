import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/models/transaction.dart';
import 'package:store_management/ui/forms/customer_form.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class TransactionAdd extends StatefulWidget {
  const TransactionAdd({super.key, required this.customer});
  final Customer? customer;

  @override
  State<TransactionAdd> createState() => _TransactionAddState();
}

class _TransactionAddState extends State<TransactionAdd> {
  List<Transaction>? transactions;
  @override
  Widget build(BuildContext context) {
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    TextEditingController customerNameControll =
        TextEditingController(text: widget.customer?.name ?? '');
    TextEditingController payControll = TextEditingController();
    DatabaseController databaseController = Get.find();
    SettingsController settingsController = Get.find();
    Customer? customer = widget.customer;

    return Scaffold(
      appBar: AppBar(
        title: Text('New Transaction'.tr),
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verSpace,
              TypeAheadField<Customer>(
                controller: customerNameControll,
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: inputDecoration.copyWith(
                      label: Text('name'.tr),
                      suffix: TextButton.icon(
                        onPressed: () async {
                          customer = await Get.to(() => CustomerForm(),
                              arguments: customerNameControll.text);
                          customerNameControll.text = customer?.name ?? '';
                        },
                        label: Text('new customer'.tr),
                        icon: Icon(Icons.person),
                      ),
                    ),
                  );
                },
                itemBuilder: (context, item) => ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.phone),
                ),
                onSelected: (item) {
                  setState(() {
                    customer = item;
                    customerNameControll.text = customer!.name;
                    transactions = item.trasnsactions
                        .where((trans) =>
                            trans.customer.target!.id == customer!.id)
                        .toList()
                        .where(
                            (trans) => trans.gettype() == TransactionType.pay)
                        .toList();
                  });
                },
                suggestionsCallback: (text) {
                  List<Customer> customers = [];
                  customers = [
                    ...databaseController.custormers,
                    ...databaseController.suppliers
                  ];
                  return customers.where((custormer) {
                    return custormer.name
                        .toLowerCase()
                        .contains(text.toLowerCase());
                  }).toList();
                },
                emptyBuilder: (context) {
                  return ListTile(
                    title: Text('no customer found'
                        .trParams({'name': customerNameControll.text})),
                    onTap: () async {
                      customer = await Get.to(() => CustomerForm(),
                          arguments: customerNameControll.text);
                      customerNameControll.text = customer?.name ?? '';
                    },
                  );
                },
              ),
              verSpace,
              TextFormField(
                controller: payControll,
                decoration: inputDecoration.copyWith(
                  label: Text('amount'.tr),
                ),
                keyboardType: TextInputType.number,
                validator: Validatorless.multiple([
                  Validatorless.required('required'.tr),
                  Validatorless.number('number'.tr),
                ]),
              ),
              verSpace,
              Divider(),
              verSpace,
              Row(
                children: [
                  Text('Customer Balance:'.tr),
                  Expanded(child: verSpace),
                  customer != null
                      ? Text(settingsController
                          .currencyFormatter(customer!.balance()))
                      : Text('')
                ],
              ),
              verSpace,
              Divider(),
              verSpace,
              if (customer != null && transactions != null)
                Expanded(
                  child: ListView.builder(
                      itemCount: transactions?.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                              '${settingsController.currencyFormatter(transactions![index].amount)}. ${transactions![index].paymentDate()}'),
                        );
                      }),
                ),
              verSpace,
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate() &&
                        customer != null &&
                        customerNameControll.text.isNotEmpty) {
                      Transaction t = Transaction(
                        date: DateTime.now().millisecondsSinceEpoch,
                        amount: double.tryParse(payControll.text) ??
                            double.parse('${payControll.text}.0'),
                        type: 2,
                      );
                      t.customer.target = customer!;
                      databaseController.newTransaction(t);
                      Get.back();
                    }
                  },
                  child: Text('save'.tr),
                ),
              ),
              verSpace
            ],
          ),
        ),
      ),
    );
  }
}
