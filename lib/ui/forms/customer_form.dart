import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/customer.dart';
import 'package:store_management/shared/widgets.dart';
import 'package:store_management/utils/app_constants.dart';

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key, this.update = false, this.customer});
  final bool update;
  final Customer? customer;

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> with FormWidget {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController nameControll = TextEditingController();
  TextEditingController phoneControll = TextEditingController();
  DatabaseController databaseController = Get.find();
  late Customer? customer;
  late String pageTitle;

  @override
  void initState() {
    if (widget.update && widget.customer != null) {
      customer = widget.customer;
      nameControll.text = widget.customer?.name ?? '';
      phoneControll.text = widget.customer?.phone ?? '';
    } else {
      nameControll.text = Get.arguments ?? '';
    }
    pageTitle = widget.update
        ? 'update_customer'.trParams({'name': widget.customer?.name ?? ''})
        : 'add_new_custommer'.trParams({
            'name': nameControll.text,
          });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
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
                      customer = Customer(
                          name: nameControll.text, phone: phoneControll.text);
                      if (widget.update && widget.customer != null) {
                        customer!.id = widget.customer!.id;
                      }
                      databaseController.addCustomer(customer!);
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
