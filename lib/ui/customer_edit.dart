import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class CustomerEdit extends StatefulWidget {
  const CustomerEdit({super.key, required this.customer});
  final Customer customer;

  @override
  State<CustomerEdit> createState() => _CustomerEditState();
}

class _CustomerEditState extends State<CustomerEdit> {
  @override
  Widget build(BuildContext context) {
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    TextEditingController nameControll =
        TextEditingController(text: widget.customer.name);
    TextEditingController phoneControll =
        TextEditingController(text: widget.customer.phone);
    DatabaseController databaseController = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: Text('update_customer'.trParams({'name': widget.customer.name})),
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
                TextFormField(
                  controller: nameControll,
                  decoration: inputDecoration.copyWith(
                    label: Text('name'.tr),
                  ),
                  keyboardType: TextInputType.text,
                  validator: Validatorless.required('this row is required!'),
                ),
                verSpace,
                TextFormField(
                  controller: phoneControll,
                  decoration: inputDecoration.copyWith(
                    label: Text('phone'.tr),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: Validatorless.multiple([
                    Validatorless.required('required'.tr),
                    Validatorless.number('number'.tr),
                  ]),
                ),
                verSpace,
                verSpace,
                ElevatedButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Customer customer = Customer(
                          name: nameControll.text, phone: phoneControll.text);
                      customer.id = widget.customer.id;
                      customer.customerType = widget.customer.customerType;
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
