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
      Get.snackbar('خطأ'.tr, 'فشل تحميل البيانات'.tr);
    }
  }

  double get totalPurchases =>
      purchases.fold(0, (sum, item) => sum + item.totalAmount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchases'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showDateFilterDialog(),
            tooltip: 'تصفية'.tr,
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${purchases.length} ${'عملية'.tr}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                                fontSize: 15,
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
        label: Text('إضافة شراء'.tr),
      ),
    );
  }

  Widget _buildPurchaseCard(Purchase purchase) {
    final categoryName = categories
        .firstWhereOrNull((c) => c.id == purchase.categoryId)
        ?.name ?? 'غير محدد'.tr;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.receipt, color: Colors.blue),
        ),
        title: Text(
          purchase.supplierName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'رقم الفاتورة:'.tr} ${purchase.receiptNumber}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(categoryName, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _paymentStatusColor(purchase.paymentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
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
            if (purchase.notes != null && purchase.notes!.isNotEmpty)
              Text(purchase.notes!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
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
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
            Text(
              DateFormat('yyyy-MM-dd').format(purchase.purchaseDate),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _showPurchaseDetails(purchase),
        onLongPress: () => _showDeleteDialog(purchase),
      ),
    );
  }

  Color _paymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'unpaid':
        return Colors.red;
      case 'bank_transfer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'مدفوع';
      case 'partial':
        return 'جزئي';
      case 'unpaid':
        return 'غير مدفوع';
      case 'bank_transfer':
        return 'تحويل بنكي';
      default:
        return status;
    }
  }

  // Dialogs

  void _showAddPurchaseDialog() {
    _showPurchaseFormDialog();
  }

  void _showPurchaseFormDialog({Purchase? purchase}) {
    final formKey = GlobalKey<FormState>();
    final supplierController = TextEditingController(text: purchase?.supplierName);
    final receiptController = TextEditingController(text: purchase?.receiptNumber);
    final amountController = TextEditingController(text: purchase != null ? purchase.totalAmount.toString() : '');
    final notesController = TextEditingController(text: purchase?.notes);
    
    DateTime selectedDate = purchase?.purchaseDate ?? DateTime.now();
    String paymentStatus = purchase?.paymentStatus ?? 'paid';
    String? categoryId = purchase?.categoryId;

    Get.dialog(
      AlertDialog(
        title: Text(purchase == null ? 'إضافة شراء'.tr : 'تعديل شراء'.tr, style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Amount (Most important)
                  TextFormField(
                    controller: amountController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'المبلغ الإجمالي *'.tr,
                      prefixIcon: const Icon(Icons.attach_money),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'مطلوب'.tr;
                      if (double.tryParse(value) == null) return 'رقم غير صحيح'.tr;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Supplier
                  TextFormField(
                    controller: supplierController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'اسم المورد *'.tr,
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'مطلوب'.tr : null,
                  ),
                  const SizedBox(height: 12),

                  // Receipt Number
                  TextFormField(
                    controller: receiptController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'رقم الفاتورة'.tr,
                      prefixIcon: const Icon(Icons.receipt),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category
                  DropdownButtonFormField<String>(
                    value: categoryId,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'الفئة'.tr,
                      prefixIcon: const Icon(Icons.category),
                      border: const OutlineInputBorder(),
                    ),
                    items: categories.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: (v) => categoryId = v,
                  ),
                  const SizedBox(height: 12),

                  // Payment Status
                  DropdownButtonFormField<String>(
                    value: paymentStatus,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'حالة الدفع'.tr,
                      prefixIcon: const Icon(Icons.payment),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'paid', child: Text('مدفوع'.tr)),
                      DropdownMenuItem(value: 'partial', child: Text('جزئي'.tr)),
                      DropdownMenuItem(value: 'unpaid', child: Text('غير مدفوع'.tr)),
                      DropdownMenuItem(value: 'bank_transfer', child: Text('تحويل بنكي'.tr)),
                    ],
                    onChanged: (v) => paymentStatus = v!,
                  ),
                  const SizedBox(height: 12),

                  // Date
                  StatefulBuilder(
                    builder: (context, setState) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: Text('${'التاريخ:'.tr} ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: Text('تغيير'.tr),
                        ),
                      );
                    }
                  ),
                  
                  // Notes
                  TextFormField(
                    controller: notesController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'ملاحظات'.tr,
                      prefixIcon: const Icon(Icons.note),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('إلغاء'.tr)),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final double amount = double.parse(amountController.text);
                
                final newPurchase = Purchase(
                  id: purchase?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  supplierName: supplierController.text,
                  receiptNumber: receiptController.text,
                  purchaseDate: selectedDate,
                  amount: amount,
                  categoryId: categoryId,
                  paymentStatus: paymentStatus,
                  notes: notesController.text,
                  createdAt: purchase?.createdAt,
                );

                if (purchase == null) {
                  await databaseController.addPurchase(newPurchase);
                } else {
                  await databaseController.updatePurchase(newPurchase);
                }
                
                Get.back();
                loadPurchases();
                Get.snackbar(
                  'نجاح'.tr, 
                  purchase == null ? 'تمت الإضافة بنجاح'.tr : 'تم التحديث بنجاح'.tr,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: Text('حفظ'.tr),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Purchase purchase) {
    Get.dialog(
      AlertDialog(
        title: Text('تأكيد الحذف'.tr),
        content: Text('هل أنت متأكد من حذف هذه العملية؟'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('إلغاء'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await databaseController.deletePurchase(purchase.id);
              Get.back();
              loadPurchases();
            },
            child: Text('حذف'.tr),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDetails(Purchase purchase) {
    final categoryName = categories
        .firstWhereOrNull((c) => c.id == purchase.categoryId)
        ?.name ?? 'غير محدد'.tr;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info, color: Colors.blue),
            const SizedBox(width: 8),
            Text('تفاصيل العملية'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('المورد'.tr, purchase.supplierName),
            _buildDetailRow('رقم الفاتورة'.tr, purchase.receiptNumber),
            _buildDetailRow('التاريخ'.tr, DateFormat('yyyy-MM-dd').format(purchase.purchaseDate)),
            _buildDetailRow('المبلغ'.tr, currencyFormat.format(purchase.totalAmount)),
            _buildDetailRow('الفئة'.tr, categoryName),
            _buildDetailRow('حالة الدفع'.tr, _paymentStatusLabel(purchase.paymentStatus).tr),
            if (purchase.notes != null && purchase.notes!.isNotEmpty)
              _buildDetailRow('ملاحظات'.tr, purchase.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _showPurchaseFormDialog(purchase: purchase),
            child: Text('تعديل'.tr),
          ),
          TextButton(onPressed: () => Get.back(), child: Text('إغلاق'.tr)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showDateFilterDialog() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      loadPurchases();
    } else if (startDate != null) {
      // Clear filter option
      Get.dialog(
        AlertDialog(
          title: Text('إلغاء التصفية؟'.tr),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('لا'.tr),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  startDate = null;
                  endDate = null;
                });
                Get.back();
                loadPurchases();
              },
              child: Text('نعم'.tr),
            ),
          ],
        ),
      );
    }
  }
}