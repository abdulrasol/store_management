import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/shared/widgets.dart';
import 'package:store_management/utils/app_constants.dart';

class SupplierAdd extends StatefulWidget {
  const SupplierAdd({super.key});

  @override
  State<SupplierAdd> createState() => _SupplierAddState();
}

class _SupplierAddState extends State<SupplierAdd> with FormWidget {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController nameControll = TextEditingController();
  TextEditingController phoneControll = TextEditingController();
  DatabaseController databaseController = Get.find();
  @override
  Widget build(BuildContext context) {
    String? name = Get.arguments;
    nameControll.text = name ?? '';
    return Scaffold(
      appBar: AppBar(
        title: name == null
            ? Text('Add New Supplier'.tr)
            : Text('${'Add New Supplier'.tr} $name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Image.asset(
                  'assets/png/customer.png',
                  scale: 3,
                ),
                verSpace,
                verSpace,
                verSpace,
                verSpace,
                textInput(nameControll,
                    label: 'name', validator: [requiredValidator]),
                verSpace,
                textInput(phoneControll,
                    label: 'phone', validator: [numberValidator]),
                verSpace,
                verSpace,
                ElevatedButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Customer customer = Customer(
                          name: nameControll.text,
                          phone: phoneControll.text,
                          customerType: 1);
                      databaseController.addCustomer(customer);
                      Get.back(result: customer);
                    }
                  },
                  label: Text('save'.tr),
                  icon: Icon(Icons.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
