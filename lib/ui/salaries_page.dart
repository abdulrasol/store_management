import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/salary.dart';

class SalariesPage extends StatefulWidget {
  const SalariesPage({super.key});

  @override
  State<SalariesPage> createState() => _SalariesPageState();
}

class _SalariesPageState extends State<SalariesPage>
    with SingleTickerProviderStateMixin {
  final DatabaseController databaseController = Get.find<DatabaseController>();
  List<Employee> employees = [];
  List<Salary> salaries = [];
  bool isLoading = false;
  DateTime selectedMonth = DateTime.now();
  int currentTab = 0;
  late TabController _tabController;

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => currentTab = _tabController.index);
      }
    });
    loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final empResult = await databaseController.getEmployees();
      final salResult = await databaseController.getSalariesByMonth(selectedMonth);
      setState(() {
        employees = empResult;
        salaries = salResult;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('خطأ'.tr, 'فشل تحميل البيانات'.tr);
    }
  }

  double get totalSalaries => salaries.fold(0, (sum, s) => sum + s.totalSalary);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الرواتب'.tr),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.people), text: 'الموظفين'.tr),
            Tab(icon: const Icon(Icons.payments), text: 'الرواتب'.tr),
          ],
        ),
        actions: [
          if (currentTab == 1)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectMonth,
              tooltip: 'اختيار الشهر'.tr,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadData,
            tooltip: 'تحديث'.tr,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmployeesTab(),
          _buildSalariesTab(),
        ],
      ),
      floatingActionButton: currentTab == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddEmployeeDialog,
              icon: const Icon(Icons.person_add),
              label: Text('إضافة موظف'.tr),
            )
          : FloatingActionButton.extended(
              onPressed: _showAddSalaryDialog,
              icon: const Icon(Icons.add),
              label: Text('إضافة راتب'.tr),
            ),
    );
  }

  Widget _buildEmployeesTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'لا يوجد موظفين'.tr,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddEmployeeDialog,
              icon: const Icon(Icons.person_add),
              label: Text('إضافة موظف'.tr),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: const Icon(Icons.person, color: Colors.teal),
            ),
            title: Text(
              employee.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(employee.phone),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditEmployeeDialog(employee),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEmployee(employee),
                ),
              ],
            ),
            onTap: () => _showEmployeeDetails(employee),
          ),
        );
      },
    );
  }

  Widget _buildSalariesTab() {
    return Column(
      children: [
        // Month Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.teal.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                _formatMonth(selectedMonth),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ),

        // Summary Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 40, color: Colors.teal.shade300),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إجمالي الرواتب'.tr,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        currencyFormat.format(totalSalaries),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${salaries.length} ${'موظف'.tr}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        // Salaries List
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : salaries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payments_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد رواتب لهذا الشهر'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: salaries.length,
                      itemBuilder: (context, index) {
                        final salary = salaries[index];
                        return _buildSalaryCard(salary);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSalaryCard(Salary salary) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: const Icon(Icons.person, color: Colors.teal),
        ),
        title: Text(
          salary.employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${'الأساسي:'.tr} ${currencyFormat.format(salary.baseSalary)}'),
            if (salary.bonus > 0)
              Text('${'مكافأة:'.tr} +${currencyFormat.format(salary.bonus)}',
                  style: const TextStyle(color: Colors.green)),
            if (salary.deductions > 0)
              Text('${'خصومات:'.tr} -${currencyFormat.format(salary.deductions)}',
                  style: const TextStyle(color: Colors.red)),
          ],
        ),
        trailing: Text(
          currencyFormat.format(salary.totalSalary),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.teal,
          ),
        ),
        onTap: () => _showSalaryDetails(salary),
      ),
    );
  }

  void _showAddEmployeeDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String phone = '';
    String email = '';
    String notes = '';

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_add, color: Colors.teal),
            const SizedBox(width: 8),
            Text('إضافة موظف جديد'.tr),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'اسم الموظف *'.tr,
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'مطلوب'.tr : null,
                  onSaved: (value) => name = value ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف *'.tr,
                    prefixIcon: const Icon(Icons.phone),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'مطلوب'.tr : null,
                  onSaved: (value) => phone = value ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني'.tr,
                    prefixIcon: const Icon(Icons.email),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => email = value ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  style: const TextStyle(fontSize: 12),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final employee = Employee(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  phone: phone,
                  email: email.isNotEmpty ? email : null,
                  notes: notes.isNotEmpty ? notes : null,
                );
                await databaseController.addEmployee(employee);
                Get.back();
                loadData();
                Get.snackbar(
                  'نجاح'.tr,
                  'تم إضافة الموظف بنجاح'.tr,
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

  void _showEditEmployeeDialog(Employee employee) {
    final formKey = GlobalKey<FormState>();
    String name = employee.name;
    String phone = employee.phone;
    String email = employee.email ?? '';
    String notes = employee.notes ?? '';

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: Colors.teal),
            const SizedBox(width: 8),
            Text('تعديل موظف'.tr),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'اسم الموظف *'.tr,
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'مطلوب'.tr : null,
                  onSaved: (value) => name = value ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: phone,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف *'.tr,
                    prefixIcon: const Icon(Icons.phone),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'مطلوب'.tr : null,
                  onSaved: (value) => phone = value ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: email,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني'.tr,
                    prefixIcon: const Icon(Icons.email),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => email = value ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: notes,
                  style: const TextStyle(fontSize: 12),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final updated = employee.copyWith(
                  name: name,
                  phone: phone,
                  email: email.isNotEmpty ? email : null,
                  notes: notes.isNotEmpty ? notes : null,
                );
                await databaseController.updateEmployee(updated);
                Get.back();
                loadData();
                Get.snackbar(
                  'نجاح'.tr,
                  'تم تحديث الموظف بنجاح'.tr,
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

  void _showEmployeeDetails(Employee employee) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.teal),
            const SizedBox(width: 8),
            Text('بيانات الموظف'.tr),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('الاسم'.tr, employee.name),
            _buildDetailRow('الهاتف'.tr, employee.phone),
            if (employee.email != null)
              _buildDetailRow('البريد الإلكتروني'.tr, employee.email!),
            if (employee.notes != null)
              _buildDetailRow('ملاحظات'.tr, employee.notes!),
            _buildDetailRow(
              'تاريخ الإضافة'.tr,
              DateFormat('yyyy-MM-dd').format(employee.createdAt),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إغلاق'.tr, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _deleteEmployee(Employee employee) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('تأكيد الحذف'.tr),
        content: Text('هل أنت متأكد من حذف ${employee.name}؟'.tr),
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
      await databaseController.deleteEmployee(employee.id);
      loadData();
      Get.snackbar(
        'نجاح'.tr,
        'تم حذف الموظف بنجاح'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  void _showAddSalaryDialog() {
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
    double baseSalary = 0;
    double bonus = 0;
    double deductions = 0;
    String notes = '';

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.payments, color: Colors.teal),
            const SizedBox(width: 8),
            Text('إضافة راتب'.tr),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            double total = baseSalary + bonus - deductions;

            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Employee>(
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
                        setDialogState(() => selectedEmployee = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'الراتب الأساسي *'.tr,
                        prefixIcon: const Icon(Icons.money),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'مطلوب'.tr : null,
                      onChanged: (value) {
                        setDialogState(() {
                          baseSalary = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'مكافآت'.tr,
                        prefixIcon: const Icon(Icons.add_circle, color: Colors.green),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: '0',
                      onChanged: (value) {
                        setDialogState(() {
                          bonus = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'خصومات'.tr,
                        prefixIcon: const Icon(Icons.remove_circle, color: Colors.red),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: '0',
                      onChanged: (value) {
                        setDialogState(() {
                          deductions = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'ملاحظات'.tr,
                        prefixIcon: const Icon(Icons.note),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onSaved: (value) => notes = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الإجمالي:'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            currencyFormat.format(total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
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
              if (formKey.currentState!.validate() && selectedEmployee != null) {
                formKey.currentState!.save();
                final salary = Salary(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  employeeId: selectedEmployee!.id,
                  employeeName: selectedEmployee!.name,
                  month: selectedMonth,
                  baseSalary: baseSalary,
                  bonus: bonus,
                  deductions: deductions,
                  notes: notes.isNotEmpty ? notes : null,
                );
                await databaseController.addSalary(salary);
                Get.back();
                loadData();
                Get.snackbar(
                  'نجاح'.tr,
                  'تم إضافة الراتب بنجاح'.tr,
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

  void _showSalaryDetails(Salary salary) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.payments, color: Colors.teal),
            const SizedBox(width: 8),
            Text('تفاصيل الراتب'.tr),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('الموظف'.tr, salary.employeeName),
            _buildDetailRow(
              'الشهر'.tr,
              _formatMonth(salary.month),
            ),
            _buildDetailRow('الراتب الأساسي'.tr, currencyFormat.format(salary.baseSalary)),
            if (salary.bonus > 0)
              _buildDetailRow('المكافآت'.tr, '+${currencyFormat.format(salary.bonus)}'),
            if (salary.deductions > 0)
              _buildDetailRow('الخصومات'.tr, '-${currencyFormat.format(salary.deductions)}'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجمالي:'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  currencyFormat.format(salary.totalSalary),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            if (salary.notes != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow('ملاحظات'.tr, salary.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  title: Text('تأكيد الحذف'.tr),
                  content: Text('هل أنت متأكد من حذف هذا الراتب؟'.tr),
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
                await databaseController.deleteSalary(salary.id);
                Get.back();
                loadData();
                Get.snackbar(
                  'نجاح'.tr,
                  'تم حذف الراتب بنجاح'.tr,
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

  void _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
      loadData();
    }
  }

  String _formatMonth(DateTime month) {
    final locale = Get.locale?.languageCode == 'ar' ? 'ar' : 'en';
    try {
      return DateFormat('MMMM yyyy', locale).format(month);
    } catch (_) {
      return DateFormat('MMMM yyyy', 'en').format(month);
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
}
