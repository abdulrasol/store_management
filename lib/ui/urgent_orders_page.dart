import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/urgent_order.dart';

class UrgentOrdersPage extends StatefulWidget {
  const UrgentOrdersPage({super.key});

  @override
  State<UrgentOrdersPage> createState() => _UrgentOrdersPageState();
}

class _UrgentOrdersPageState extends State<UrgentOrdersPage> {
  final DatabaseController databaseController = Get.find<DatabaseController>();
  List<UrgentOrder> orders = [];
  bool isLoading = false;
  bool showCompleted = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final result = await databaseController.getUrgentOrders();
      setState(() {
        orders = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('خطأ'.tr, 'فشل تحميل البيانات'.tr);
    }
  }

  List<UrgentOrder> get filteredOrders {
    if (showCompleted) return orders;
    return orders.where((o) => !o.isCompleted).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الطلبات المستعجلة'.tr),
        actions: [
          FilterChip(
            label: Text(
              'المكتملة'.tr,
              style: TextStyle(
                color: showCompleted ? Colors.white : null,
                fontSize: 12,
              ),
            ),
            selected: showCompleted,
            onSelected: (value) => setState(() => showCompleted = value),
            selectedColor: Colors.orange.shade700,
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color: showCompleted ? Colors.orange.shade700 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadData,
            tooltip: 'تحديث'.tr,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.priority_high_rounded,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد طلبات مستعجلة'.tr,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddOrderDialog,
                        icon: const Icon(Icons.add),
                        label: Text('إضافة طلب'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _buildOrderCard(order);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOrderDialog,
        icon: const Icon(Icons.add),
        label: Text('طلب جديد'.tr),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildOrderCard(UrgentOrder order) {
    final dateStr = DateFormat('yyyy-MM-dd').format(order.date);
    final isOverdue = !order.isCompleted && order.date.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: order.isCompleted
              ? Colors.green.shade200
              : isOverdue
                  ? Colors.red.shade200
                  : Colors.orange.shade200,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: order.isCompleted
              ? Colors.green.shade100
              : isOverdue
                  ? Colors.red.shade100
                  : Colors.orange.shade100,
          child: Icon(
            order.isCompleted
                ? Icons.check_circle
                : isOverdue
                    ? Icons.warning_rounded
                    : Icons.priority_high_rounded,
            color: order.isCompleted
                ? Colors.green
                : isOverdue
                    ? Colors.red
                    : Colors.orange,
          ),
        ),
        title: Text(
          order.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: order.isCompleted ? TextDecoration.lineThrough : null,
            color: order.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${'الكمية:'.tr} ${order.quantity.toStringAsFixed(order.quantity.truncateToDouble() == order.quantity ? 0 : 2)}'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: isOverdue && !order.isCompleted ? Colors.red : null,
                  ),
                ),
              ],
            ),
            if (order.notes != null && order.notes!.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.note_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: order.isCompleted
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteOrder(order),
              )
            : null,
        onTap: () => _showOrderDetails(order),
      ),
    );
  }

  void _showAddOrderDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    DateTime orderDate = DateTime.now();

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.add_circle, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text('إضافة طلب مستعجل'.tr)),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم الطلب *'.tr,
                        prefixIcon: const Icon(Icons.shopping_bag),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'مطلوب'.tr;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: quantityController,
                      decoration: InputDecoration(
                        labelText: 'الكمية *'.tr,
                        prefixIcon: const Icon(Icons.numbers),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'مطلوب'.tr;
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'أدخل رقم صحيح'.tr;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text('التاريخ'.tr),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(orderDate)),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: orderDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => orderDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
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
              if (formKey.currentState!.validate()) {
                final order = UrgentOrder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  quantity: double.parse(quantityController.text.trim()),
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                  date: orderDate,
                );
                await databaseController.addUrgentOrder(order);
                Get.back();
                loadData();
                Get.snackbar(
                  'نجاح'.tr,
                  'تم إضافة الطلب بنجاح'.tr,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('حفظ'.tr),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(UrgentOrder order) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              order.isCompleted ? Icons.check_circle : Icons.priority_high_rounded,
              color: order.isCompleted ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('تفاصيل الطلب'.tr)),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('اسم الطلب'.tr, order.name),
            _buildDetailRow(
              'الكمية'.tr,
              order.quantity.toStringAsFixed(
                  order.quantity.truncateToDouble() == order.quantity ? 0 : 2),
            ),
            _buildDetailRow('التاريخ'.tr, DateFormat('yyyy-MM-dd').format(order.date)),
            _buildDetailRow(
              'الحالة'.tr,
              order.isCompleted ? 'مكتمل'.tr : 'قيد التنفيذ'.tr,
            ),
            if (order.notes != null && order.notes!.isNotEmpty)
              _buildDetailRow('ملاحظات'.tr, order.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _deleteOrder(order);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('حذف'.tr),
          ),
          if (!order.isCompleted)
            ElevatedButton.icon(
              onPressed: () async {
                final updated = order.copyWith(isCompleted: true);
                await databaseController.updateUrgentOrder(updated);
                Get.back();
                loadData();
                Get.snackbar(
                  'نجاح'.tr,
                  'تم اكتمال الطلب'.tr,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
              icon: const Icon(Icons.check),
              label: Text('تم اكتمال الطلب'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          if (order.isCompleted)
            ElevatedButton(
              onPressed: () => Get.back(),
              child: Text('إغلاق'.tr),
            ),
        ],
      ),
    );
  }

  void _deleteOrder(UrgentOrder order) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('تأكيد الحذف'.tr),
        content: Text('هل أنت متأكد من حذف هذا الطلب؟'.tr),
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
      await databaseController.deleteUrgentOrder(order.id);
      loadData();
      Get.snackbar(
        'نجاح'.tr,
        'تم حذف الطلب بنجاح'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
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
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
