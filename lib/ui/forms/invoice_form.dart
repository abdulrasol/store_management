import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/invoice_item.dart';
import 'package:store_management/models/item.dart';
import 'package:store_management/ui/invoice_save.dart';
import 'package:store_management/ui/invoice_save_update.dart';
import 'package:store_management/utils/app_constants.dart';
import 'package:validatorless/validatorless.dart';

class InvoiceForm extends StatefulWidget {
  const InvoiceForm({super.key, this.invoice});
  final Invoice? invoice;

  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController quantityController = TextEditingController(text: '1');
  TextEditingController sellPriceController = TextEditingController(text: '0');
  TextEditingController costPriceController = TextEditingController(text: '0'); // New for Custom Items

  SettingsController settingsController = Get.find();
  DatabaseController databaseController = Get.find();

  Item? tempItem;
  InvoiceItem? tempInvoiceItem;
  late Invoice invoice;
  late final Map<String, Map<String, dynamic>>? oldItemMap;

  bool isCustomItem = false; // Toggle for Ad-Hoc/Service items

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      invoice = widget.invoice!;
      // Prepare map for tracking changes if updating
      oldItemMap = {
        for (var item in invoice.items)
          item.itemName: {
            'quantity': item.quantity,
            'id': item.item.targetId,
            'total-quantity': item.item.target?.quantity ?? 0 // Handle null target safely
          }
      };
    } else {
      invoice = Invoice();
      oldItemMap = null;
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    // Refresh items only if we are in update mode or generally leaving?
    // Kept from original logic
    databaseController.loading();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'Create New Invoice'.tr : 'Update Invoice'.tr),
        actions: [
          if (widget.invoice != null)
            TextButton.icon(
              onPressed: () {
                Get.defaultDialog(
                  title: 'Alert'.tr,
                  middleText: 'Are you sure to delete this invoice? there no way to recover just create new one!'.tr,
                  onCancel: () {
                    Get.back();
                  },
                  cancel: TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
                  onConfirm: () {
                    databaseController.deleteInvoice(widget.invoice!); // use widget.invoice! directly
                    Get.close(3); // Close dialog and page
                  },
                  textConfirm: 'Delete'.tr,
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                );
              },
              icon: Icon(Icons.delete_forever, color: Colors.red),
              label: Text('Delete'.tr, style: TextStyle(color: Colors.red)),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Item Entry Form ---
            Form(
              key: formKey,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isCustomItem ? 'Details (Service/Custom)'.tr : 'Select Item'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Text("Custom Item".tr),
                              Switch(
                                  value: isCustomItem,
                                  onChanged: (val) {
                                    setState(() {
                                      isCustomItem = val;
                                      clearForm();
                                    });
                                  }),
                            ],
                          )
                        ],
                      ),
                      verSpace,
                      if (isCustomItem)
                        TextFormField(
                          controller: nameController,
                          decoration: inputDecoration.copyWith(label: Text('Item Name'.tr), hintText: 'e.g. Delivery, Service...'),
                          validator: Validatorless.required('required'.tr),
                        )
                      else
                        TypeAheadField<Item>(
                          controller: nameController,
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              autofocus: !isCustomItem, // Only autofocus if selecting item
                              decoration: inputDecoration.copyWith(label: Text('item'.tr)),
                            );
                          },
                          itemBuilder: (context, item) => ListTile(
                            title: Text(item.name),
                            subtitle: Text('${settingsController.currencyFormatter(item.sellPrice)}, ${item.quantity} ${'available'.tr}'),
                          ),
                          onSelected: (item) {
                            setState(() {
                              nameController.text = item.name;
                              tempItem = item;
                              sellPriceController.text = item.sellPrice.toString();
                              // Auto-fill cost price for internal tracking logic if needed,
                              // though we usually don't edit it here for DB items.
                            });
                          },
                          suggestionsCallback: (text) {
                            return databaseController.items
                                .where((item) => item.quantity > 0 || widget.invoice != null) // Allow 0 quantity if editing (might need to return item)
                                .toList()
                                .where((item) => item.name.toLowerCase().contains(text.toLowerCase()))
                                .toList();
                          },
                        ),
                      verSpace,
                      verSpace,
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: sellPriceController,
                              decoration: inputDecoration.copyWith(label: Text('Sell Price'.tr)),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              validator: Validatorless.multiple([
                                Validatorless.required('required'.tr),
                                Validatorless.number('number'.tr),
                              ]),
                            ),
                          ),
                          horSpace,
                          Expanded(
                            child: TextFormField(
                              controller: quantityController,
                              decoration: inputDecoration.copyWith(label: Text('quantity'.tr)),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              validator: Validatorless.multiple([
                                Validatorless.required('required'.tr),
                                Validatorless.number('number'.tr),
                              ]),
                            ),
                          ),
                          if (isCustomItem) ...[
                            horSpace,
                            Expanded(
                              child: TextFormField(
                                controller: costPriceController,
                                decoration: inputDecoration.copyWith(label: Text('Buy Price'.tr)), // Or Cost
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: Validatorless.multiple([
                                  Validatorless.required('required'.tr),
                                  Validatorless.number('number'.tr),
                                ]),
                              ),
                            ),
                          ],
                        ],
                      ),
                      verSpace,
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => handleAddOrUpdateItem(),
                          child: Text(tempInvoiceItem != null ? 'Update'.tr : 'Add'.tr),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            verSpace,
            Divider(),
            verSpace,

            // --- Items List ---
            Text('Invoice Items'.tr, style: Theme.of(context).textTheme.titleMedium),
            verSpace,
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: [
                          DataColumn(label: Text('Action')), // # replaced with Action
                          DataColumn(label: Text('item'.tr)),
                          DataColumn(label: Text('Price'.tr)),
                          DataColumn(label: Text('quantity'.tr)),
                          DataColumn(label: Text('Total Price'.tr)),
                        ],
                        rows: invoice.items.map<DataRow>((item) {
                          return DataRow(
                            cells: [
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'edit'.tr,
                                    onPressed: () => editItem(item),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'delete'.tr,
                                    onPressed: () {
                                      setState(() {
                                        invoice.items.remove(item);
                                      });
                                    },
                                  ),
                                ],
                              )),
                              DataCell(Text(item.itemName + (item.item.target == null ? ' (Custom)' : ''))),
                              DataCell(Text(settingsController.currencyFormatter(item.saledPrice()))),
                              DataCell(Text(item.quantity.toString())),
                              DataCell(Text(settingsController.currencyFormatter(item.totalPrice()))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (invoice.items.isNotEmpty) {
            if (widget.invoice == null) {
              // Creating new
              Get.to(() => InvoiceSave(invoice: invoice));
            } else {
              // Updating existing
              if (oldItemMap != null) {
                Get.to(() => InvoiceSaveUpdate(
                      oldItemMap: oldItemMap!,
                      invoice: invoice,
                    ));
              }
            }
          } else {
            Get.snackbar('Error', 'Please add at least one item');
          }
        },
        label: Text('Next'.tr),
        icon: Icon(Icons.arrow_forward),
      ),
    );
  }

  void clearForm() {
    nameController.clear();
    quantityController.text = '1';
    sellPriceController.text = '0';
    costPriceController.text = '0'; // Only relevant for custom
    tempItem = null;
    tempInvoiceItem = null;
  }

  void handleAddOrUpdateItem() {
    if (!formKey.currentState!.validate()) return;

    final String name = nameController.text;
    final double sellPrice = double.tryParse(sellPriceController.text) ?? 0;
    final int quantity = int.tryParse(quantityController.text) ?? 1;
    final double buyPrice = double.tryParse(costPriceController.text) ?? 0; // Only for custom

    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter item name');
      return;
    }

    // Logic for Database Items
    if (!isCustomItem) {
      if (tempItem == null) {
        // User typed a name but didn't select from TypeAhead?
        // Treat as error for now unless we implicitly create DB Item (not requested).
        // OR: switch to Custom Item logic if tempItem is null?
        Get.snackbar('Error', 'Please select an item from the list or switch to Custom Item');
        return;
      }

      // Check stock
      // If updating, we need to account for the quantity already in the invoice item (if it's the same item)
      // Logic from `invoice_update.dart` updateItem:
      // if ((quantity - tempInvoiceItem!.quantity) <= tempItem!.quantity)

      // Let's simplify.
      // If Add: check quota.
      // If Update: check quota taking into account difference.

      int currentStock = tempItem!.quantity;
      int requestedQty = quantity;

      if (tempInvoiceItem != null) {
        // Updating
        // If we are updating the SAME item
        if (tempInvoiceItem!.item.targetId == tempItem!.id) {
          // allow if new_qty <= stock + old_qty
          // actually stock in DB is already reduced if we are in Update Invoice mode?
          // Wait, `invoice_update` logic:
          // `tempItem!.quantity += tempInvoiceItem!.quantity.toInt(); // Restore old`
          // `tempItem!.quantity -= quantity; // Deduct new`

          // If we are merely editing the FORM 'invoice_form', the DB is NOT updated yet until we hit Save in `InvoiceSaveUpdate`.
          // HOWEVER, `invoice_update.dart` seemed to do: `databaseController.objectBox.itemBox.put(tempItem!);` directly inside `updateItem`.
          // This is dangerous if the user cancels.

          // BETTER APPROACH: Just validate against what we know.
          // `invoice.items` list is in memory.
          // The Stock Item `tempItem` is from DB.
          // If NEW INVOICE: Stock is full.
          // If UPDATE INVOICE: The Item in DB already has reduced stock FROM THIS INVOICE?
          // Let's check `invoice_create.dart`. It just adds to `invoice.items`. It does NOT deduct stock yet. Stock is deducted in `database_controller.createInvoice`.

          // So for Create: `quantity <= tempItem!.quantity`

          // For Update: The invoice ALREADY exists. The items in it were already deducted from stock presumably?
          // Actually `database_controller.updateInvoice` handles the diff.
          // So usually `tempItem` represents CURRENT DB State.
          // If I bought 5 apples, and DB says 5 left. Total was 10.
          // In InvoiceUpdate, I see 5 apples in invoice.
          // If I want to change to 6 apples.
          // I need 1 more. DB has 5. 1 <= 5. OK.
          // Logic: `requestedDiff = newQty - oldQty`. `if (requestedDiff <= currentStock)`.

          int oldQty = tempInvoiceItem!.quantity;
          int diff = requestedQty - oldQty;
          if (diff > currentStock) {
            Get.snackbar('Stock Error', 'Not enough stock. Available: $currentStock');
            return;
          }
        }
      } else {
        // Adding new item to list
        if (requestedQty > currentStock) {
          Get.snackbar('Stock Error', 'Not enough stock. Available: $currentStock');
          return;
        }
      }
    }

    // Logic to Add/Update Object
    setState(() {
      if (tempInvoiceItem != null) {
        // Update existing in list
        tempInvoiceItem!.itemName = name;
        tempInvoiceItem!.quantity = quantity;
        tempInvoiceItem!.itemSellPrice = sellPrice;
        tempInvoiceItem!.itemBuyPrice = isCustomItem ? buyPrice : (tempItem?.buyPrice ?? tempInvoiceItem!.itemBuyPrice);
        if (isCustomItem) {
          tempInvoiceItem!.item.target = null; // Detach if switched to custom
        } else {
          tempInvoiceItem!.item.target = tempItem;
        }
        // Discount logic? Kept simple 0 for now or preserve old
        // Original code calculated discount based on entered price vs original price.
        if (!isCustomItem && tempItem != null) {
          if (sellPrice < tempItem!.sellPrice) {
            tempInvoiceItem!.discount = tempItem!.sellPrice - sellPrice;
          } else {
            tempInvoiceItem!.discount = 0;
          }
        }
      } else {
        // Add New
        double discount = 0;
        if (!isCustomItem && tempItem != null) {
          if (sellPrice < tempItem!.sellPrice) {
            discount = tempItem!.sellPrice - sellPrice;
          }
        }

        var newItem = InvoiceItem(
            itemName: name,
            quantity: quantity,
            itemSellPrice: sellPrice,
            itemBuyPrice: isCustomItem ? buyPrice : (tempItem?.buyPrice ?? 0),
            discount: discount);
        if (!isCustomItem) {
          newItem.item.target = tempItem;
        }

        invoice.items.add(newItem);
      }

      // Clear form
      clearForm();
    });
  }

  void editItem(InvoiceItem item) {
    setState(() {
      tempInvoiceItem = item;
      nameController.text = item.itemName;
      quantityController.text = item.quantity.toString();
      sellPriceController.text = item.itemSellPrice.toString();
      costPriceController.text = item.itemBuyPrice.toString();

      if (item.item.target != null) {
        isCustomItem = false;
        tempItem = item.item.target;
      } else {
        isCustomItem = true;
        tempItem = null;
      }
    });
  }
}
