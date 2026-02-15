import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/purchase.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  final DatabaseController databaseController = Get.find<DatabaseController>();
  List<Purchase> purchases = [];
  List<PurchaseCategory> categories = [];
  bool isLoading = false;
  DateTime? startDate;
  DateTime? endDate;
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'ar_AE',
    symbol: 'AED ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    loadPurchases();
    loadCategories();
  }

  Future<void> loadCategories() async {
    categories = await databaseController.getPurchaseCategories();
  }

  Future<void> loadPurchases() async {
    setState(() => isLoading = true);
    try {
      final result = await databaseController.getPurchases(
        startDate: startDate,
        endDate: endDate,
      );
      setState(() {
        purchases = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error'.tr, 'Failed to load purchases'.tr);
    }
  }

  double get totalPurchases => purchases.fold(0, (sum, p) => sum + p.totalAmount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المشتريات'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showDateFilterDialog,
            tooltip: 'تصفية بالتاريخ'.tr,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadPurchases,
            tooltip: 'تحديث'.tr,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 40, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إجمالي المشتريات'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          currencyFormat.format(totalPurchases),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${purchases.length} ${'عملية'.tr}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          
          // Purchases List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : purchases.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد مشتريات'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: purchases.length,
                        itemBuilder: (context, index) {
                          final purchase = purchases[index];
                          return _buildPurchaseCard(purchase);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPurchaseDialog,
        icon: const Icon(Icons.add),
        label: Text('إضافة مشتريات'.tr),
      ),
    );
  }

  Widget _buildPurchaseCard(Purchase purchase) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.shopping_cart, color: Colors.blue),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                purchase.supplierName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _paymentStatusColor(purchase.paymentStatus).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _paymentStatusLabel(purchase.paymentStatus).tr,
                style: TextStyle(
                  fontSize: 12,
                  color: _paymentStatusColor(purchase.paymentStatus),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${'رقم الفاتورة:'.tr} ${purchase.receiptNumber}'),
            Text('${'تاريخ الشراء:'.tr} ${DateFormat('yyyy-MM-dd').format(purchase.purchaseDate)}'),
            if (purchase.notes != null && purchase.notes!.isNotEmpty)
              Text('${'ملاحظات:'.tr} ${purchase.notes}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(purchase.totalAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${purchase.items.length} ${'أصناف'.tr}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => _showPurchaseDetails(purchase),
      ),
    );
  }

  void _showAddPurchaseDialog() {
    final formKey = GlobalKey<FormState>();
    final supplierNames = databaseController.suppliers.map((s) => s.name).toSet().toList()..sort();
    String? supplierName = supplierNames.isNotEmpty ? supplierNames.first : null;
    String receiptNumber = '';
    final receiptNumberController = TextEditingController();
    DateTime purchaseDate = DateTime.now();
    String paymentStatus = 'paid';
    String notes = '';
    List<PurchaseItem> items = [];
    PurchaseCategory? selectedCategory;

    // For adding items
    final itemNameController = TextEditingController();
    final itemQuantityController = TextEditingController();
    final itemPriceController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('إضافة مشتريات جديدة'.tr),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            double currentTotal = items.fold(
              0,
              (sum, item) => sum + (item.quantity * item.unitPrice),
            );

            return SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Supplier Name
                    DropdownButtonFormField<String>(
                      value: supplierName,
                      decoration: InputDecoration(
                        labelText: 'اسم المورد *'.tr,
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                      items: supplierNames.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: supplierNames.isEmpty
                          ? null
                          : (value) => setDialogState(() => supplierName = value),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'مطلوب'.tr : null,
                    ),
                    const SizedBox(height: 12),

                    // Receipt Number
                    TextFormField(
                      controller: receiptNumberController,
                      decoration: InputDecoration(
                        labelText: 'رقم الفاتورة/الوصل *'.tr,
                        prefixIcon: const Icon(Icons.receipt),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'مطلوب'.tr;
                        }
                        return null;
                      },
                      onSaved: (value) => receiptNumber = value?.trim() ?? '',
                    ),
                    const SizedBox(height: 12),

                    // Purchase Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text('تاريخ الشراء'.tr),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd').format(purchaseDate),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: purchaseDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => purchaseDate = picked);
                          }
                        },
                        child: Text('تغيير'.tr),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payment Status
                    DropdownButtonFormField<String>(
                      value: paymentStatus,
                      decoration: InputDecoration(
                        labelText: 'حالة الدفع *'.tr,
                        prefixIcon: const Icon(Icons.payment),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'paid',
                          child: Text('مدفوع بالكامل'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'partial',
                          child: Text('دفع جزئي'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'unpaid',
                          child: Text('غير مدفوع'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('تحويل بنكي'.tr),
                        ),
                      ],
                      onChanged: (value) => paymentStatus = value!,
                    ),
                    const SizedBox(height: 12),

                    // Items Section
                    Text(
                      'الأصناف المشتراة'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Category Dropdown
                    DropdownButtonFormField<PurchaseCategory>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'الفئة'.tr,
                        prefixIcon: const Icon(Icons.category),
                        border: const OutlineInputBorder(),
                      ),
                      hint: Text('اختر الفئة'.tr),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Add Item Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: itemNameController,
                            decoration: InputDecoration(
                              labelText: 'اسم الصنف'.tr,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: itemQuantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'الكمية'.tr,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: itemPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'السعر'.tr,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (itemNameController.text.isNotEmpty &&
                              itemQuantityController.text.isNotEmpty &&
                              itemPriceController.text.isNotEmpty) {
                            setDialogState(() {
                              items.add(PurchaseItem(
                                itemName: itemNameController.text,
                                quantity: double.parse(itemQuantityController.text),
                                unitPrice: double.parse(itemPriceController.text),
                              ));
                              itemNameController.clear();
                              itemQuantityController.clear();
                              itemPriceController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: Text('إضافة الصنف'.tr),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Items List
                    if (items.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              dense: true,
                              title: Text(item.itemName),
                              subtitle: Text(
                                '${item.quantity} × ${currencyFormat.format(item.unitPrice)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currencyFormat.format(item.total),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setDialogState(() => items.removeAt(index));
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإجمالي:'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currencyFormat.format(currentTotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'ملاحظات'.tr,
                        prefixIcon: const Icon(Icons.note),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onSaved: (value) => notes = value ?? '',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() &&
                  receiptNumberController.text.trim().isNotEmpty &&
                  items.isNotEmpty) {
                formKey.currentState!.save();
                
                final purchase = Purchase(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  supplierName: supplierName ?? '',
                  receiptNumber: receiptNumber,
                  purchaseDate: purchaseDate,
                  items: items,
                  paymentStatus: paymentStatus,
                  notes: notes.isNotEmpty ? notes : null,
                );

                await databaseController.addPurchase(purchase);
                Get.back();
                loadPurchases();
                Get.snackbar(
                  'نجاح'.tr,
                  'تم إضافة المشتريات بنجاح'.tr,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else if (items.isEmpty) {
                Get.snackbar(
                  'تنبيه'.tr,
                  'يجب إضافة صنف واحد على الأقل'.tr,
                  backgroundColor: Colors.orange,
                );
              }
            },
            child: Text('حفظ'.tr),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDetails(Purchase purchase) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text('تفاصيل المشتريات'.tr)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('المورد'.tr, purchase.supplierName),
              _buildDetailRow('رقم الفاتورة'.tr, purchase.receiptNumber),
              _buildDetailRow(
                'تاريخ الشراء'.tr,
                DateFormat('yyyy-MM-dd').format(purchase.purchaseDate),
              ),
              _buildDetailRow(
                'حالة الدفع'.tr,
                _paymentStatusLabel(purchase.paymentStatus).tr,
              ),
              if (purchase.notes != null)
                _buildDetailRow('ملاحظات'.tr, purchase.notes!),
              const Divider(),
              Text(
                'الأصناف المشتراة'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...purchase.items.map((item) => Card(
                    child: ListTile(
                      dense: true,
                      title: Text(item.itemName),
                      subtitle: Text(
                        '${item.quantity} × ${currencyFormat.format(item.unitPrice)}',
                      ),
                      trailing: Text(
                        currencyFormat.format(item.total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإجمالي الكلي'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    currencyFormat.format(purchase.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  title: Text('تأكيد الحذف'.tr),
                  content: Text('هل أنت متأكد من حذف هذه المشتريات؟'.tr),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: Text('إلغاء'.tr),
                    ),
                    ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('حذف'.tr),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await databaseController.deletePurchase(purchase.id);
                Get.back();
                loadPurchases();
                Get.snackbar(
                  'نجاح'.tr,
                  'تم حذف المشتريات بنجاح'.tr,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('حذف'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: Text('إغلاق'.tr),
          ),
        ],
      ),
    );
  }

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'مدفوع بالكامل';
      case 'partial':
        return 'دفع جزئي';
      case 'unpaid':
        return 'غير مدفوع';
      case 'bank_transfer':
        return 'تحويل بنكي';
      default:
        return 'غير مدفوع';
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green.shade700;
      case 'partial':
        return Colors.orange.shade700;
      case 'bank_transfer':
        return Colors.blue.shade700;
      case 'unpaid':
      default:
        return Colors.red.shade700;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showDateFilterDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('تصفية بالتاريخ'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('من تاريخ'.tr),
              subtitle: Text(startDate != null
                  ? DateFormat('yyyy-MM-dd').format(startDate!)
                  : 'غير محدد'.tr),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                    Get.back();
                    _showDateFilterDialog();
                  }
                },
                child: Text('اختيار'.tr),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('إلى تاريخ'.tr),
              subtitle: Text(endDate != null
                  ? DateFormat('yyyy-MM-dd').format(endDate!)
                  : 'غير محدد'.tr),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => endDate = picked);
                    Get.back();
                    _showDateFilterDialog();
                  }
                },
                child: Text('اختيار'.tr),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                startDate = null;
                endDate = null;
              });
              Get.back();
              loadPurchases();
            },
            child: Text('إلغاء التصفية'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              loadPurchases();
            },
            child: Text('تطبيق'.tr),
          ),
        ],
      ),
    );
  }
}
