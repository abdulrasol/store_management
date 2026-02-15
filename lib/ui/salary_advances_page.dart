import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/salary.dart';

class SalaryAdvancesPage extends StatefulWidget {
  const SalaryAdvancesPage({super.key});

  @override
  State<SalaryAdvancesPage> createState() => _SalaryAdvancesPageState();
}

class _SalaryAdvancesPageState extends State<SalaryAdvancesPage> {
  final DatabaseController databaseController = Get.find<DatabaseController>();
  List<Employee> employees = [];
  List<SalaryAdvance> advances = [];
  List<SalaryAdvance> filteredAdvances = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  NumberFormat get currencyFormat {
    final localeCode = Get.locale?.languageCode == 'ar' ? 'ar_AE' : 'en_AE';
    return NumberFormat.currency(
      locale: localeCode,
      symbol: 'AED ',
      decimalDigits: 2,
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
    _searchController.addListener(_filterAdvances);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final empResult = await databaseController.getEmployees();
      final advResult = await databaseController.getPendingAdvances();
      setState(() {
        employees = empResult;
        advances = advResult;
        filteredAdvances = advResult;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('خطأ'.tr, 'فشل تحميل البيانات'.tr);
    }
  }

  void _filterAdvances() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredAdvances = advances;
      } else {
        filteredAdvances = advances
            .where((a) =>
                a.employeeName.toLowerCase().contains(query) ||
                a.amount.toString().contains(query) ||
                (a.reason?.toLowerCase().contains(query) ?? false))
            .toList();
      }
    });
  }

  double get totalPending => filteredAdvances.fold(0, (sum, a) => sum + a.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('السلف والقروض'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadData,
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
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 40, color: Colors.orange.shade300),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إجمالي السلف غير المسددة'.tr,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          currencyFormat.format(totalPending),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${filteredAdvances.length} سلفة'.tr,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن سلفة...'.tr,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Advances List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAdvances.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.money_off,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              advances.isEmpty
                                  ? 'لا توجد سلف'.tr
                                  : 'لا توجد نتائج للبحث'.tr,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredAdvances.length,
                        itemBuilder: (context, index) {
                          return _buildAdvanceCard(filteredAdvances[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAdvanceDialog,
        icon: const Icon(Icons.add),
        label: Text('إضافة سلفة'.tr),
      ),
    );
  }

  Widget _buildAdvanceCard(SalaryAdvance advance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: const Icon(Icons.account_balance_wallet, color: Colors.orange),
        ),
        title: Text(
          advance.employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${'المبلغ:'.tr} ${currencyFormat.format(advance.amount)}'),
            Text('${'التاريخ:'.tr} ${DateFormat('yyyy-MM-dd').format(advance.requestDate)}'),
            if (advance.reason != null && advance.reason!.isNotEmpty)
              Text('${'السبب:'.tr} ${advance.reason}', maxLines: 1, overflow: TextOverflow.ellipsis),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'غير مسددة'.tr,
                style: const TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteAdvance(advance),
        ),
      ),
    );
  }

  void _showAddAdvanceDialog() {
    if (employees.isEmpty) {
      Get.snackbar(
        'تنبيه'.tr,
        'يجب إضافة موظفين أولاً'.tr,
        backgroundColor: Colors.orange,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    Employee? selectedEmployee = employees.first;
    double amount = 0;
    String reason = '';

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.orange),
            const SizedBox(width: 8),
            Text('إضافة سلفة جديدة'.tr, style: const TextStyle(fontSize: 15)),
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
                    DropdownButtonFormField<Employee>(
                      style: const TextStyle(fontSize: 12),
                      value: selectedEmployee,
                      decoration: InputDecoration(
                        labelText: 'الموظف *'.tr,
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                      items: employees.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedEmployee = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'المبلغ *'.tr,
                        prefixIcon: const Icon(Icons.money),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'مطلوب'.tr;
                        if (double.tryParse(value) == null) return 'رقم غير صحيح'.tr;
                        if (double.parse(value) <= 0) return 'يجب أن يكون أكبر من صفر'.tr;
                        return null;
                      },
                      onChanged: (value) {
                        amount = double.tryParse(value) ?? 0;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'السبب / السبب الديني الحاجة (اختياري)'.tr,
                        prefixIcon: const Icon(Icons.note),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onSaved: (value) => reason = value ?? '',
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
            child: Text('إلغاء'.tr, style: const TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && selectedEmployee != null) {
                formKey.currentState!.save();
                
                final advance = SalaryAdvance(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  employeeId: selectedEmployee!.id,
                  employeeName: selectedEmployee!.name,
                  amount: amount,
                  reason: reason.isNotEmpty ? reason : null,
                  requestDate: DateTime.now(),
                );
                
                await databaseController.addSalaryAdvance(advance);
                Get.back();
                loadData();
                Get.snackbar(
                  'نجاح'.tr,
                  'تم إضافة السلفة بنجاح'.tr,
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

  void _deleteAdvance(SalaryAdvance advance) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('تأكيد الحذف'.tr, style: const TextStyle(fontSize: 15)),
        content: Text(
          'هل أنت متأكد من حذف سلفة ${advance.employeeName}؟'.tr,
        ),
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
      await databaseController.deleteSalaryAdvance(advance.id);
      loadData();
      Get.snackbar(
        'نجاح'.tr,
        'تم حذف السلفة بنجاح'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }
}