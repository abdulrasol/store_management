import 'package:flutter/material.dart'
    show TextFormField, TextEditingController, Text, TextInputType;
import 'package:flutter/widgets.dart' show FormFieldValidator;
import 'package:get/get.dart';
import 'package:validatorless/validatorless.dart';

import '../utils/app_constants.dart' show inputDecoration;

mixin FormWidget {
  // validtors
  final requiredValidator = Validatorless.required('required'.tr);
  final numberValidator = Validatorless.number('number'.tr);

  TextFormField textInput(TextEditingController controll,
          { List<FormFieldValidator<String>> validator = const [],
          String? label}) =>
      TextFormField(
        controller: controll,
        decoration: inputDecoration.copyWith(
          label: label != null ? Text(label.tr) : null,
        ),
        keyboardType: TextInputType.text,
        validator: Validatorless.multiple(validator),
      );
}
