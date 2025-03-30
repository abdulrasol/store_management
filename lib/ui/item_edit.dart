import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/item.dart';

import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class EditItem extends StatefulWidget {
  const EditItem({super.key, required this.itemModel});
  final Item itemModel;

  @override
  State<EditItem> createState() => _EditItemState();
}

class _EditItemState extends State<EditItem> {
  DatabaseController databaseController = Get.find();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    TextEditingController nameControll =
        TextEditingController(text: widget.itemModel.name);

    TextEditingController buyControll =
        TextEditingController(text: widget.itemModel.buyPrice.toString());
    TextEditingController sellControll =
        TextEditingController(text: widget.itemModel.sellPrice.toString());
    TextEditingController quaControll =
        TextEditingController(text: widget.itemModel.quantity.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text('New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
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
              // TextFormField(
              //   controller: fromControll,
              //   decoration: inputDecoration.copyWith(
              //     label: Text('From'),
              //   ),
              //   keyboardType: TextInputType.text,
              //   validator: Validatorless.required('this row is required!'),
              // ),
              // verSpace,
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
              verSpace,
              TextButton.icon(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Be cearful?'),
                          content: Text('Are you sure to delete this item?'),
                          actions: [
                            TextButton.icon(
                              onPressed: () {},
                              label: Text('No'),
                              icon: Icon(Icons.remove_circle_outline_sharp),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                databaseController
                                    .deleteItem(widget.itemModel.id);

                                Get.close(3);
                              },
                              label: Text('Yes'),
                              icon:
                                  Icon(Icons.delete_forever, color: Colors.red),
                            ),
                          ],
                        );
                      });
                },
                label: Text('delete item'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            setState(() {
              databaseController.updateItem(
                widget.itemModel.id,
                name: nameControll.text,

                //  from: fromControll.text,
                buyPrice: double.tryParse('${buyControll.text}.0') ??
                    double.parse(buyControll.text),
                sellPrice: double.tryParse('${sellControll.text}.0') ??
                    double.parse(sellControll.text),
                qunatity: int.tryParse(quaControll.text) ??
                    int.parse(quaControll.text.split('.')[0]),
              );
              Get.close(2);
            });
          }
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
