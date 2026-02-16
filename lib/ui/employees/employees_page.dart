import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:store_management/controllers/employees_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/employee.dart';
import 'package:store_management/models/salary_transaction.dart';
import 'package:store_management/ui/employees/employee_report_page.dart';
import 'package:store_management/ui/reports/employees_report_page.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final EmployeesController controller = Get.put(EmployeesController());
  final SettingsController settingsController = Get.find<SettingsController>();

  @override
  void initState() {
    super.initState();
    controller.loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('employees'.tr),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Get.to(() => EmployeesReportPage(
                dateRange: DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 30)),
                  end: DateTime.now(),
                ),
              ));
            },
            tooltip: 'employees_report'.tr,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.employees.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.loadEmployees,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryCards(),
                const SizedBox(height: 20),
                _buildEmployeesList(),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEmployeeDialog(),
        icon: const Icon(Icons.person_add),
        label: Text('add_employee'.tr),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline, size: 64, color: Colors.teal.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            'no_employees'.tr,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'add_employee_hint'.tr,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddEmployeeDialog(),
            icon: const Icon(Icons.person_add),
            label: Text('add_employee'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    double totalSalaries = controller.employees.fold(0, (sum, e) => sum + e.salary);
    int activeCount = controller.employees.where((e) => e.status == 'active').length;

    return Row(
      children: [
        Expanded(
          child: _buildGradientCard(
            title: 'employees'.tr,
            value: controller.employees.length.toString(),
            subtitle: '$activeCount ${'active'.tr}',
            colors: [Colors.teal.shade400, Colors.teal.shade600],
            icon: Icons.people,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGradientCard(
            title: 'total_salaries'.tr,
            value: settingsController.currencyFormatter(totalSalaries),
            subtitle: 'per_month'.tr,
            colors: [Colors.indigo.shade400, Colors.indigo.shade600],
            icon: Icons.account_balance_wallet,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientCard({
    required String title,
    required String value,
    required String subtitle,
    required List<Color> colors,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesList() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'employees_list'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${controller.employees.length} ${'employee'.tr}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.employees.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200, indent: 76),
            itemBuilder: (context, index) {
              final employee = controller.employees[index];
              return _buildEmployeeItem(employee);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeItem(Employee employee) {
    return _buildEmployeeContent(employee);
  }

  Widget _buildEmployeeContent(Employee employee) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (employee.status) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'active'.tr;
        break;
      case 'vacation':
        statusColor = Colors.orange;
        statusIcon = Icons.beach_access;
        statusText = 'vacation'.tr;
        break;
      case 'suspended':
        statusColor = Colors.red;
        statusIcon = Icons.block;
        statusText = 'suspended'.tr;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.person;
        statusText = 'unknown'.tr;
    }

    return InkWell(
      onTap: () => Get.to(() => EmployeeReportPage(employee: employee)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade300, Colors.teal.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  employee.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 9,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.jobTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        employee.phone,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  settingsController.currencyFormatter(employee.salary),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'per_month'.tr,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_left, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAddEmployeeDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final jobCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            Text('add_employee'.tr),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameCtrl, 'name'.tr, Icons.person),
              const SizedBox(height: 12),
              _buildTextField(phoneCtrl, 'phone'.tr, Icons.phone, type: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(jobCtrl, 'job_title'.tr, Icons.work),
              const SizedBox(height: 12),
              _buildTextField(salaryCtrl, 'salary'.tr, Icons.attach_money, type: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || salaryCtrl.text.isEmpty) {
                Get.snackbar('error'.tr, 'fill_required'.tr, backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }

              final newEmployee = Employee(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text,
                phone: phoneCtrl.text,
                jobTitle: jobCtrl.text,
                salary: double.tryParse(salaryCtrl.text) ?? 0,
                status: 'active',
              );

              final success = await controller.addEmployee(newEmployee);
              if (success) {
                Get.back();
                Get.snackbar(
                  'success'.tr,
                  'employee_added'.tr,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  void _showQuickTransactionDialog(Employee employee, String type) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    Color color;
    IconData icon;
    String title;

    switch (type) {
      case 'withdraw':
        color = Colors.orange;
        icon = Icons.money_off;
        title = 'add_withdraw'.tr;
        break;
      case 'deduction':
        color = Colors.red;
        icon = Icons.remove_circle;
        title = 'add_deduction'.tr;
        break;
      case 'bonus':
        color = Colors.green;
        icon = Icons.add_circle;
        title = 'add_bonus'.tr;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        title = 'add_transaction'.tr;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade300, Colors.teal.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          employee.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${'salary'.tr}: ${settingsController.currencyFormatter(employee.salary)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Amount Field
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'amount'.tr,
                  prefixIcon: Icon(Icons.attach_money, color: color),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Notes Field
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: '${'notes'.tr} (${'optional'.tr})',
                  prefixIcon: Icon(Icons.note, color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
              ),
              // Quick Amount Buttons
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickAmountButton(amountCtrl, '50', color),
                  _buildQuickAmountButton(amountCtrl, '100', color),
                  _buildQuickAmountButton(amountCtrl, '200', color),
                  _buildQuickAmountButton(amountCtrl, '500', color),
                  if (employee.salary > 0)
                    _buildQuickAmountButton(
                      amountCtrl,
                      employee.salary.toStringAsFixed(0),
                      color,
                      label: 'full_salary'.tr,
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountCtrl.text.isEmpty) {
                Get.snackbar('error'.tr, 'enter_amount'.tr, backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }

              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) {
                Get.snackbar('error'.tr, 'invalid_amount'.tr, backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }

              final transaction = SalaryTransaction(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                employeeId: employee.id,
                employeeName: employee.name,
                type: type,
                amount: amount,
                date: DateTime.now(),
                notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
              );

              await controller.addTransaction(transaction);
              _loadData(); // Refresh employee data if needed
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(TextEditingController controller, String amount, Color color, {String? label}) {
    return InkWell(
      onTap: () => controller.text = amount,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label ?? amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _loadData() {
    controller.loadEmployees();
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
