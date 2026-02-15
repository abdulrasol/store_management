import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:store_management/controllers/employees_controller.dart';
import 'package:store_management/models/employee.dart';
import 'package:store_management/models/salary_transaction.dart';
import 'package:store_management/ui/employees/employee_report_page.dart';

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject controller
    final controller = Get.put(EmployeesController());

    final primaryColor = Colors.teal;
    final isDark = Get.isDarkMode;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الموظفين'.tr),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Obx(() => _buildStatItem('إجمالي الموظفين', '${controller.employees.length}', Icons.groups)),
                Obx(() => _buildStatItem('نشط', '${controller.activeCount}', Icons.check_circle_outline)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.filterEmployees,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الوظيفة...'.tr,
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Employees List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (controller.filteredEmployees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text('لا يوجد موظفين'.tr, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredEmployees.length,
                itemBuilder: (context, index) {
                  final emp = controller.filteredEmployees[index];
                  // If cardColor is null (unlikely with ternary), fallback to white/grey
                  return _buildEmployeeCard(emp, controller, context, cardColor ?? Colors.white, textColor);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEmployeeDialog(context, controller, null),
        label: Text('إضافة موظف'.tr),
        icon: const Icon(Icons.add),
        backgroundColor: primaryColor,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 28),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label.tr, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  Widget _buildEmployeeCard(Employee emp, EmployeesController controller, BuildContext context, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.teal.withOpacity(0.1),
          child: Text(
            emp.name.isNotEmpty ? emp.name[0] : '?',
            style: const TextStyle(fontSize: 20, color: Colors.teal, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          emp.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.work_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(emp.jobTitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(emp.phone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ],
        ),
        trailing: _buildActionsMenu(controller, emp, context),
      ),
    );
  }

  Widget _buildActionsMenu(EmployeesController controller, Employee emp, BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (value) {
        if (value == 'transactions') {
          _showTransactionsDialog(context, controller, emp);
        } else if (value == 'report') {
          Get.to(() => EmployeeReportPage(employee: emp));
        } else if (value == 'edit') {
          _showEmployeeDialog(context, controller, emp);
        } else if (value == 'delete') {
          Get.defaultDialog(
            title: 'حذف موظف'.tr,
            middleText: '${'هل أنت متأكد من حذف'.tr} ${emp.name}؟',
            textConfirm: 'نعم'.tr,
            textCancel: 'إلغاء'.tr,
            confirmTextColor: Colors.white,
            onConfirm: () {
              controller.deleteEmployee(emp.id);
              Get.back();
            },
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'transactions',
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text('المعاملات المالية'.tr),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.blueGrey, size: 18),
              const SizedBox(width: 8),
              Text('تقرير'.tr),
            ],
          ),
        ),
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
    );
  }

  void _showTransactionsDialog(BuildContext context, EmployeesController controller, Employee emp) {
    controller.loadEmployeeTransactions(emp.id);
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${'المعاملات المالية'.tr}: ${emp.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Add Transaction Button
              ElevatedButton.icon(
                onPressed: () => _showAddTransactionForm(context, controller, emp),
                icon: const Icon(Icons.add, size: 18),
                label: Text('سحب / خصم / مكافأة'.tr),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              ),
              const SizedBox(height: 10),
              const Divider(),
              // List
              Expanded(
                child: Obx(() {
                  if (controller.employeeTransactions.isEmpty) {
                    return Center(child: Text('لا توجد معاملات'.tr, style: const TextStyle(color: Colors.grey)));
                  }
                  return ListView.builder(
                    itemCount: controller.employeeTransactions.length,
                    itemBuilder: (context, index) {
                      final trans = controller.employeeTransactions[index];
                      Color color = Colors.blue;
                      IconData icon = Icons.info;
                      String label = trans.type;
                      
                      if (trans.type == 'withdraw') {
                        color = Colors.orange;
                        icon = Icons.money_off; 
                        label = 'سحب'.tr;
                      } else if (trans.type == 'deduction') {
                        color = Colors.red;
                        icon = Icons.remove_circle_outline;
                        label = 'خصم'.tr;
                      } else if (trans.type == 'bonus') {
                        color = Colors.green;
                        icon = Icons.add_circle_outline;
                        label = 'مكافأة'.tr;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
                          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('yyyy-MM-dd').format(trans.date) + (trans.notes != null ? '\n${trans.notes}' : '')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${trans.amount}',
                                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey, size: 18),
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: 'حذف'.tr,
                                    middleText: 'هل أنت متأكد؟'.tr,
                                    textConfirm: 'نعم'.tr,
                                    textCancel: 'إلغاء'.tr,
                                    confirmTextColor: Colors.white,
                                    onConfirm: () => controller.deleteTransaction(trans.id, emp.id),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('إغلاق'.tr)),
        ],
      ),
    );
  }

  void _showAddTransactionForm(BuildContext context, EmployeesController controller, Employee emp) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'withdraw'; // default
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('إضافة معاملة'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: InputDecoration(
                    labelText: 'النوع'.tr,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: [
                    DropdownMenuItem(value: 'withdraw', child: Text('سحب من الراتب'.tr)),
                    DropdownMenuItem(value: 'deduction', child: Text('خصم (جزاء)'.tr)),
                    DropdownMenuItem(value: 'bonus', child: Text('مكافأة'.tr)),
                  ],
                  onChanged: (v) => type = v!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'المبلغ'.tr,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  validator: (v) => v!.isEmpty ? 'مطلوب'.tr : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات'.tr,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('إلغاء'.tr, style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final transaction = SalaryTransaction(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  employeeId: emp.id,
                  employeeName: emp.name,
                  type: type,
                  amount: double.tryParse(amountCtrl.text) ?? 0,
                  date: DateTime.now(),
                  notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                );
                controller.addTransaction(transaction);
                // Don't close manually here, controller handles back+refresh
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text('حفظ'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDialog(BuildContext context, EmployeesController controller, Employee? emp) {
    final nameCtrl = TextEditingController(text: emp?.name ?? '');
    final phoneCtrl = TextEditingController(text: emp?.phone ?? '');
    final jobCtrl = TextEditingController(text: emp?.jobTitle ?? '');
    final salaryCtrl = TextEditingController(text: emp?.salary.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(emp == null ? 'إضافة موظف'.tr : 'تعديل بيانات'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameCtrl, 'الاسم'.tr, Icons.person),
                const SizedBox(height: 12),
                _buildTextField(phoneCtrl, 'رقم الهاتف'.tr, Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(jobCtrl, 'المسمى الوظيفي'.tr, Icons.work),
                const SizedBox(height: 12),
                _buildTextField(salaryCtrl, 'الراتب الأساسي'.tr, Icons.monetization_on, type: TextInputType.number),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('إلغاء'.tr, style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newEmp = Employee(
                  id: emp?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  jobTitle: jobCtrl.text,
                  salary: double.tryParse(salaryCtrl.text) ?? 0,
                  status: emp?.status ?? 'active',
                  createdAt: emp?.createdAt,
                );

                if (emp == null) {
                  controller.addEmployee(newEmp);
                } else {
                  controller.updateEmployee(newEmp);
                }
                Get.back();
                Get.snackbar(
                  'نجاح'.tr, 
                  emp == null ? 'تمت إضافة الموظف'.tr : 'تم تحديث البيانات'.tr,
                  backgroundColor: Colors.green, 
                  colorText: Colors.white, 
                  snackPosition: SnackPosition.BOTTOM
                );
              }
            },
            child: Text('حفظ'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (v) => v!.isEmpty ? 'مطلوب'.tr : null,
    );
  }
}
