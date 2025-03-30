import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class CustomerAdd extends StatefulWidget {
  const CustomerAdd({super.key});

  @override
  State<CustomerAdd> createState() => _CustomerAddState();
}

class _CustomerAddState extends State<CustomerAdd> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController nameControll = TextEditingController();
  TextEditingController phoneControll = TextEditingController();
  DatabaseController databaseController = Get.find();
  @override
  Widget build(BuildContext context) {
    nameControll.text = Get.arguments ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text('add_new_custommer'.trParams({
          'name': nameControll.text,
        })),
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
                  validator: Validatorless.required('required'.tr),
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
