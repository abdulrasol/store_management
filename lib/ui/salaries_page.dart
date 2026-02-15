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
  List<Salary> filteredSalaries = [];
  Map<String, double> employeeAdvances = {};
  bool isLoading = false;
  DateTime selectedMonth = DateTime.now();
  int currentTab = 0;
  late TabController _tabController;

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => currentTab = _tabController.index);
      }
    });
    loadData();
    _searchController.addListener(_filterSalaries);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final empResult = await databaseController.getEmployees();
      final salResult = await databaseController.getSalariesByMonth(selectedMonth);
      
      Map<String, double> advances = {};
      for (var emp in empResult) {
        advances[emp.id] = await databaseController.getEmployeePendingAdvances(emp.id);
      }
      
      setState(() {
        employees = empResult;
        salaries = salResult;
        filteredSalaries = salResult;
        employeeAdvances = advances;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('خطأ'.tr, 'فشل تحميل البيانات'.tr);
    }
  }

  void _filterSalaries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredSalaries = salaries;
      } else {
        filteredSalaries = salaries
            .where((s) =>
                s.employeeName.toLowerCase().contains(query) ||
                s.totalSalary.toString().contains(query))
            .toList();
      }
    });
  }

  double get totalSalaries => filteredSalaries.fold(0, (sum, s) => sum + s.totalSalary);

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
          if (currentTab == 1) ...[
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectMonth,
              tooltip: 'اختيار الشهر'.tr,
            ),
            IconButton(
              icon: const Icon(Icons.account_balance_wallet),
              onPressed: () => Get.to(() => const SalaryAdvancesPage()),
              tooltip: 'السلف والقروض'.tr,
            ),
          ],
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
              style: const TextStyle(fontSize: 15, color: Colors.grey),
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
        final lastSalary = _getLastSalaryForEmployee(employee.id);
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.phone),
                if (lastSalary != null)
                  Text('آخر راتب: ${currencyFormat.format(lastSalary.totalSalary)} (${_formatMonth(lastSalary.month)})'),
                if (employeeAdvances[employee.id] != null && employeeAdvances[employee.id]! > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      'سلفة مستحقة: ${currencyFormat.format(employeeAdvances[employee.id]!)}',
                      style: const TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
              ],
            ),
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

  Salary? _getLastSalaryForEmployee(String employeeId) {
    final empSalaries = salaries.where((s) => s.employeeId == employeeId).toList()
      ..sort((a, b) => b.month.compareTo(a.month));
    return empSalaries.isNotEmpty ? empSalaries.first : null;
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

        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث عن راتب...'.tr,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
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
                  '${filteredSalaries.length} ${'موظف'.tr}',
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
              : filteredSalaries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payments_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            salaries.isEmpty
                                ? 'لا توجد رواتب لهذا الشهر'.tr
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
                      itemCount: filteredSalaries.length,
                      itemBuilder: (context, index) {
                        final salary = filteredSalaries[index];
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormat.format(salary.totalSalary),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.teal,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditSalaryDialog(salary);
                } else if (value == 'delete') {
                  _deleteSalary(salary);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Text('تعديل'.tr),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Text('حذف'.tr),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
            Text('إضافة موظف جديد'.tr, style: const TextStyle(fontSize: 15)),
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
            child: Text('إلغاء'.tr, style: const TextStyle(fontSize: 14)),
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
            Text('تعديل موظف'.tr, style: const TextStyle(fontSize: 15)),
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
            child: Text('إلغاء'.tr, style: const TextStyle(fontSize: 14)),
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
            Text('بيانات الموظف'.tr, style: const TextStyle(fontSize: 15)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 16),
              final lastSalary = _getLastSalaryForEmployee(employee.id);
              if (lastSalary != null)
                Card(
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payments, size: 18, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text('آخر راتب مسجل'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow('الشهر'.tr, _formatMonth(lastSalary.month)),
                        _buildDetailRow('الإجمالي'.tr, currencyFormat.format(lastSalary.totalSalary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
        title: Text('تأكيد الحذف'.tr, style: const TextStyle(fontSize: 15)),
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

    _showSalaryFormDialog();
  }

  void _showEditSalaryDialog(Salary salary) {
    _showSalaryFormDialog(salary: salary);
  }

  void _showSalaryFormDialog({Salary? salary}) {
    final formKey = GlobalKey<FormState>();
    Employee? selectedEmployee = employees.firstWhere(
      (e) => e.id == salary?.employeeId,
      orElse: () => employees.first,
    );
    double baseSalary = salary?.baseSalary ?? 0;
    double bonus = salary?.bonus ?? 0;
    double deductions = salary?.deductions ?? 0;
    String notes = salary?.notes ?? '';

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.payments, color: Colors.teal),
            const SizedBox(width: 8),
            Text(salary == null ? 'إضافة راتب'.tr : 'تعديل راتب'.tr,
                style: const TextStyle(fontSize: 15)),
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
                      onChanged: salary == null
                          ? (value) {
                              setDialogState(() => selectedEmployee = value);
                            }
                          : null,
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
                      initialValue: baseSalary > 0 ? baseSalary.toString() : null,
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
                      initialValue: bonus > 0 ? bonus.toString() : '0',
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
                      initialValue: deductions > 0 ? deductions.toString() : '0',
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
            child: Text('إلغاء'.tr, style: const TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && selectedEmployee != null) {
                formKey.currentState!.save();
                
                if (salary == null) {
                  final newSalary = Salary(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    employeeId: selectedEmployee!.id,
                    employeeName: selectedEmployee!.name,
                    month: selectedMonth,
                    baseSalary: baseSalary,
                    bonus: bonus,
                    deductions: deductions,
                    notes: notes.isNotEmpty ? notes : null,
                  );
                  await databaseController.addSalary(newSalary);
                  Get.back();
                  loadData();
                  Get.snackbar(
                    'نجاح'.tr,
                    'تم إضافة الراتب بنجاح'.tr,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  final updatedSalary = salary.copyWith(
                    employeeId: selectedEmployee!.id,
                    employeeName: selectedEmployee!.name,
                    baseSalary: baseSalary,
                    bonus: bonus,
                    deductions: deductions,
                    notes: notes.isNotEmpty ? notes : null,
                  );
                  await databaseController.updateSalary(updatedSalary);
                  Get.back();
                  loadData();
                  Get.snackbar(
                    'نجاح'.tr,
                    'تم تعديل الراتب بنجاح'.tr,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: Text(salary == null ? 'حفظ'.tr : 'تحديث'.tr),
          ),
        ],
      ),
    );
  }

  void _deleteSalary(Salary salary) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('تأكيد الحذف'.tr, style: const TextStyle(fontSize: 15)),
        content: Text(
          'هل أنت متأكد من حذف راتب ${salary.employeeName}؟'.tr,
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
      await databaseController.deleteSalary(salary.id);
      loadData();
      Get.snackbar(
        'نجاح'.tr,
        'تم حذف الراتب بنجاح'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  void _showSalaryDetails(Salary salary) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.payments, color: Colors.teal),
            const SizedBox(width: 8),
            Text('تفاصيل الراتب'.tr, style: const TextStyle(fontSize: 15)),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('الموظف'.tr, salary.employeeName),
            _buildDetailRow('الشهر'.tr, _formatMonth(salary.month)),
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
                    fontSize: 15,
                  ),
                ),
                Text(
                  currencyFormat.format(salary.totalSalary),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.teal,
                  ),
                ),
              ],
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

  void _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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