import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class AddItem extends StatefulWidget {
  const AddItem({super.key});

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  DatabaseController databaseController = Get.find();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController nameControll = TextEditingController();
  TextEditingController codeControll = TextEditingController();
  TextEditingController fromControll = TextEditingController();
  TextEditingController buyControll = TextEditingController();
  TextEditingController sellControll = TextEditingController();
  TextEditingController quaControll = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Image.asset(
                  'assets/png/item.png',
                  scale: 3,
                ),
                verSpace,
                verSpace,
                TextFormField(
                  controller: nameControll,
                  decoration: inputDecoration.copyWith(
                    label: Text('Item Name'),
                  ),
                  keyboardType: TextInputType.text,
                  validator: Validatorless.required('this row is required!'),
                ),
                verSpace,
                TextFormField(
                  controller: codeControll,
                  decoration: inputDecoration.copyWith(
                    label: Text('Code'),
                  ),
                  keyboardType: TextInputType.text,
                ),
                verSpace,
                TextFormField(
                  controller: fromControll,
                  decoration: inputDecoration.copyWith(
                    label: Text('From'),
                  ),
                  keyboardType: TextInputType.text,
                  validator: Validatorless.required('this row is required!'),
                ),
                verSpace,
                TextFormField(
                  controller: buyControll,
                  decoration: inputDecoration.copyWith(
                    label: Text('Buy Price'),
                  ),
                  keyboardType: TextInputType.number,
                  validator: Validatorless.multiple([
                    Validatorless.required('this row is required!'),
                    Validatorless.number('number only'),
                  ]),
                ),
                verSpace,
                TextFormField(
                  controller: sellControll,
                  decoration: inputDecoration.copyWith(
                    label: Text('Sell Price'),
                  ),
                  keyboardType: TextInputType.number,
                  validator: Validatorless.multiple([
                    Validatorless.required('this row is required!'),
                    Validatorless.number('number only'),
                  ]),
                ),
                verSpace,
                TextFormField(
                  controller: quaControll,
                  decoration: inputDecoration.copyWith(
                    label: Text('Quantity'),
                  ),
                  keyboardType: TextInputType.number,
                  validator: Validatorless.multiple([
                    Validatorless.required('this row is required!'),
                    Validatorless.number('number only'),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // if (formKey.currentState!.validate()) {
          //   int id = databaseController.addItem(
          //     name: nameControll.text,
          //     code: codeControll.text,
          //     from: fromControll.text,
          //     buyPrice: double.parse('${buyControll.text}.0'),
          //     sellPrice: double.parse('${sellControll.text}.0'),
          //     qunatity: int.parse(quaControll.text),
          //   );

          // Get.off(() => ItemView(item: databaseController.getItemById(id)!));
          // }
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
