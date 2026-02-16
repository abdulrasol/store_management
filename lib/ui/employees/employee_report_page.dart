// lib/ui/employees/employee_report_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:store_management/controllers/employees_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/employee.dart';
import 'package:store_management/models/salary_transaction.dart';

class EmployeeReportPage extends StatefulWidget {
  final Employee employee;
  const EmployeeReportPage({super.key, required this.employee});

  @override
  State<EmployeeReportPage> createState() => _EmployeeReportPageState();
}

class _EmployeeReportPageState extends State<EmployeeReportPage> {
  final EmployeesController controller = Get.find<EmployeesController>();
  final SettingsController settingsController = Get.find<SettingsController>();

  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  List<SalaryTransaction> transactions = [];
  double totalSalary = 0;
  double totalWithdrawals = 0;
  double totalDeductions = 0;
  double totalBonuses = 0;
  double netSalary = 0;
  double remainingFromBase = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    await controller.loadEmployeeTransactions(widget.employee.id);
    _filterData();
  }

  void _filterData() {
    setState(() {
      final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);

      transactions = controller.employeeTransactions.where((t) {
        return t.date.isAfter(start) && t.date.isBefore(end);
      }).toList();

      transactions.sort((a, b) => b.date.compareTo(a.date));

      totalSalary = widget.employee.salary;

      totalWithdrawals = transactions
          .where((t) => t.type == 'withdraw')
          .fold(0, (sum, t) => sum + t.amount);

      totalDeductions = transactions
          .where((t) => t.type == 'deduction')
          .fold(0, (sum, t) => sum + t.amount);

      totalBonuses = transactions
          .where((t) => t.type == 'bonus')
          .fold(0, (sum, t) => sum + t.amount);

      netSalary = totalSalary + totalBonuses - totalWithdrawals - totalDeductions;
      remainingFromBase = totalSalary - totalWithdrawals;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalSalary > 0 ? totalWithdrawals / totalSalary : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee.name),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDateRange,
            tooltip: 'select_period'.tr,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _generatePdf,
            tooltip: 'export_pdf'.tr,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Employee Header Card
              _buildEmployeeHeader(),
              const SizedBox(height: 16),

              // Salary Progress Card
              _buildSalaryProgressCard(progress),
              const SizedBox(height: 16),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 16),

              // Salary Summary
              _buildSalarySummaryCard(),
              const SizedBox(height: 16),

              // Transactions List
              _buildTransactionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeHeader() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (widget.employee.status) {
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
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.person;
        statusText = 'unknown'.tr;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade300, Colors.teal.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  widget.employee.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.employee.name,
                        style: const TextStyle(
                          fontSize: 16,
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
                    widget.employee.jobTitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        widget.employee.phone,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryProgressCard(double progress) {
    final isOverDrawn = progress > 1.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isOverDrawn ? Icons.warning_amber_rounded : Icons.account_balance_wallet,
                      color: isOverDrawn ? Colors.red : Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'remaining_from_salary'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOverDrawn ? Colors.red.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    settingsController.currencyFormatter(remainingFromBase),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOverDrawn ? Colors.red : Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress > 1.0 ? 1.0 : progress,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.8 ? Colors.red.shade400 : progress > 0.5 ? Colors.orange.shade400 : Colors.green.shade400,
                ),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% ${'withdrawn'.tr}',
                  style: TextStyle(
                    fontSize: 11,
                    color: progress > 0.8 ? Colors.red : Colors.grey.shade600,
                    fontWeight: progress > 0.8 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  '${'salary'.tr}: ${settingsController.currencyFormatter(totalSalary)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            if (isOverDrawn)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'overdrawn_warning'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'withdraw'.tr,
            Icons.money_off,
            Colors.orange,
            () => _showAddTransactionDialog('withdraw'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            'deduction'.tr,
            Icons.remove_circle,
            Colors.red,
            () => _showAddTransactionDialog('deduction'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            'bonus'.tr,
            Icons.add_circle,
            Colors.green,
            () => _showAddTransactionDialog('bonus'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalarySummaryCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_outlined, color: Colors.teal.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'salary_calculation'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('base_salary'.tr, totalSalary, Colors.blue),
            _buildSummaryRow('bonuses'.tr, totalBonuses, Colors.green, isAddition: true),
            _buildSummaryRow('withdrawals'.tr, totalWithdrawals, Colors.orange, isDeduction: true),
            _buildSummaryRow('deductions'.tr, totalDeductions, Colors.red, isDeduction: true),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'net_salary'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    settingsController.currencyFormatter(netSalary),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
  }

  Widget _buildSummaryRow(String label, double value, Color color, {bool isAddition = false, bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (isAddition)
                Text('+ ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              if (isDeduction)
                Text('- ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              Text(
                settingsController.currencyFormatter(value),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
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
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.teal.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'transactions'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${transactions.length} ${'transaction'.tr}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: Colors.grey.shade300, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'no_transactions'.tr,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length > 10 ? 10 : transactions.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200, indent: 70),
              itemBuilder: (context, index) {
                final t = transactions[index];
                return _buildTransactionItem(t);
              },
            ),
          if (transactions.length > 10)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '${'showing'.tr} 10 ${'of'.tr} ${transactions.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(SalaryTransaction t) {
    Color color;
    IconData icon;
    String typeLabel;
    String sign;

    switch (t.type) {
      case 'withdraw':
        color = Colors.orange;
        icon = Icons.money_off;
        typeLabel = 'withdraw'.tr;
        sign = '-';
        break;
      case 'deduction':
        color = Colors.red;
        icon = Icons.remove_circle_outline;
        typeLabel = 'deduction'.tr;
        sign = '-';
        break;
      case 'bonus':
        color = Colors.green;
        icon = Icons.add_circle_outline;
        typeLabel = 'bonus'.tr;
        sign = '+';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        typeLabel = t.type;
        sign = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(t.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                if (t.notes != null && t.notes!.isNotEmpty)
                  Text(
                    t.notes!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '$sign${settingsController.currencyFormatter(t.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(String type) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    Color color;
    IconData icon;
    String title;
    String hint;

    switch (type) {
      case 'withdraw':
        color = Colors.orange;
        icon = Icons.money_off;
        title = 'add_withdraw'.tr;
        hint = 'withdraw_hint'.tr;
        break;
      case 'deduction':
        color = Colors.red;
        icon = Icons.remove_circle;
        title = 'add_deduction'.tr;
        hint = 'deduction_hint'.tr;
        break;
      case 'bonus':
        color = Colors.green;
        icon = Icons.add_circle;
        title = 'add_bonus'.tr;
        hint = 'bonus_hint'.tr;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        title = 'add_transaction'.tr;
        hint = '';
    }

    // Show remaining balance warning for withdraw/deduction
    final remaining = totalSalary - totalWithdrawals;
    final canWithdraw = remaining > 0;

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
              if (hint.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hint,
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if ((type == 'withdraw' || type == 'deduction') && !canWithdraw)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'no_remaining_balance'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if ((type == 'withdraw' || type == 'deduction') && canWithdraw)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'remaining_balance'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      Text(
                        settingsController.currencyFormatter(remaining),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
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
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'notes'.tr + ' (${'optional'.tr})',
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: (type == 'withdraw' || type == 'deduction') && !canWithdraw
                ? null
                : () async {
                    if (amountCtrl.text.isEmpty) {
                      Get.snackbar(
                        'error'.tr,
                        'enter_amount'.tr,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    final amount = double.tryParse(amountCtrl.text) ?? 0;
                    if (amount <= 0) {
                      Get.snackbar(
                        'error'.tr,
                        'invalid_amount'.tr,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    if ((type == 'withdraw' || type == 'deduction') && amount > remaining) {
                      Get.snackbar(
                        'error'.tr,
                        'amount_exceeds_balance'.tr,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    final transaction = SalaryTransaction(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      employeeId: widget.employee.id,
                      employeeName: widget.employee.name,
                      type: type,
                      amount: amount,
                      date: DateTime.now(),
                      notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                    );

                    final success = await controller.addTransaction(transaction);
                    if (success) {
                      Get.back();
                      _loadData();
                      Get.snackbar(
                        'success'.tr,
                        'transaction_added'.tr,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: dateRange,
    );
    if (picked != null) {
      setState(() => dateRange = picked);
      _filterData();
    }
  }

  Future<void> _generatePdf() async {
    try {
      final pdf = pw.Document();

      pw.Font ttf;
      pw.Font ttfBold;

      try {
        final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        ttf = pw.Font.ttf(fontData);
        final boldFontData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
        ttfBold = pw.Font.ttf(boldFontData);
      } catch (e) {
        ttf = pw.Font.courier();
        ttfBold = pw.Font.courierBold();
      }

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('employee_report'.tr, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(widget.employee.name, style: pw.TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('${'period'.tr}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Stats Table
            pw.Table.fromTextArray(
              headers: ['item'.tr, 'value'.tr],
              data: [
                ['base_salary'.tr, settingsController.currencyFormatter(totalSalary)],
                ['bonuses'.tr, settingsController.currencyFormatter(totalBonuses)],
                ['withdrawals'.tr, settingsController.currencyFormatter(totalWithdrawals)],
                ['deductions'.tr, settingsController.currencyFormatter(totalDeductions)],
                ['net_salary'.tr, settingsController.currencyFormatter(netSalary)],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              cellAlignment: pw.Alignment.centerRight,
            ),

            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'details'.tr),

            pw.Table.fromTextArray(
              headers: ['date'.tr, 'type'.tr, 'amount'.tr, 'notes'.tr],
              data: transactions.map((t) {
                String type = t.type;
                if(type == 'withdraw') type = 'withdraw'.tr;
                if(type == 'deduction') type = 'deduction'.tr;
                if(type == 'bonus') type = 'bonus'.tr;

                return [
                  DateFormat('dd/MM/yyyy HH:mm').format(t.date),
                  type,
                  settingsController.currencyFormatter(t.amount),
                  t.notes ?? '',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerRight,
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/emp_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      await Printing.sharePdf(bytes: bytes, filename: 'employee_report.pdf');
    } catch (e) {
      Get.snackbar('Error'.tr, e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
