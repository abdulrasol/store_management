import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/employees_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/employee.dart';
import 'package:store_management/models/salary_transaction.dart';
import 'package:store_management/ui/employees/employee_report_page.dart';

class EmployeesReportPage extends StatefulWidget {
  final DateTimeRange dateRange;

  const EmployeesReportPage({super.key, required this.dateRange});

  @override
  State<EmployeesReportPage> createState() => _EmployeesReportPageState();
}

class _EmployeesReportPageState extends State<EmployeesReportPage> {
  final DatabaseController databaseController = Get.find<DatabaseController>();
  final SettingsController settingsController = Get.find<SettingsController>();
  final EmployeesController employeesController = Get.find<EmployeesController>();

  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  bool isLoading = false;

  List<Employee> employees = [];
  List<Map<String, dynamic>> employeeSummaries = [];

  double totalBaseSalaries = 0;
  double totalWithdrawals = 0;
  double totalBonuses = 0;
  double totalDeductions = 0;
  double totalNetSalaries = 0;
  int totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    dateRange = widget.dateRange;
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    employees = await databaseController.getEmployees();

    employeeSummaries = [];
    totalBaseSalaries = 0;
    totalWithdrawals = 0;
    totalBonuses = 0;
    totalDeductions = 0;
    totalNetSalaries = 0;
    totalTransactions = 0;

    final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
    final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);

    for (var employee in employees) {
      await employeesController.loadEmployeeTransactions(employee.id);

      final transactions = employeesController.employeeTransactions.where((t) {
        return t.date.isAfter(start) && t.date.isBefore(end);
      }).toList();

      double withdrawals = transactions
          .where((t) => t.type == 'withdraw')
          .fold(0, (sum, t) => sum + t.amount);

      double bonuses = transactions
          .where((t) => t.type == 'bonus')
          .fold(0, (sum, t) => sum + t.amount);

      double deductions = transactions
          .where((t) => t.type == 'deduction')
          .fold(0, (sum, t) => sum + t.amount);

      double netSalary = employee.salary + bonuses - withdrawals - deductions;
      double remainingFromBase = employee.salary - withdrawals;

      employeeSummaries.add({
        'employee': employee,
        'withdrawals': withdrawals,
        'bonuses': bonuses,
        'deductions': deductions,
        'netSalary': netSalary,
        'remaining': remainingFromBase,
        'transactions': transactions,
        'transactionCount': transactions.length,
      });

      totalBaseSalaries += employee.salary;
      totalWithdrawals += withdrawals;
      totalBonuses += bonuses;
      totalDeductions += deductions;
      totalNetSalaries += netSalary;
      totalTransactions += transactions.length;
    }

    employeeSummaries.sort((a, b) => (b['netSalary'] as double).compareTo(a['netSalary'] as double));

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('employees_report'.tr),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildDateHeader(),
                    const SizedBox(height: 16),
                    _buildMainCardsRow(),
                    const SizedBox(height: 12),
                    _buildWithdrawalsStatusCard(),
                    const SizedBox(height: 16),
                    _buildEmployeesList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade100, Colors.cyan.shade100],
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.date_range, color: Colors.teal.shade700, size: 18),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.teal.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCardsRow() {
    final remaining = totalBaseSalaries - totalWithdrawals;

    return Row(
      children: [
        Expanded(
          child: _buildGradientStatCard(
            'total_salaries'.tr,
            settingsController.currencyFormatter(totalBaseSalaries),
            [Colors.indigo.shade400, Colors.indigo.shade600],
            Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildGradientStatCard(
            'withdrawals'.tr,
            settingsController.currencyFormatter(totalWithdrawals),
            [Colors.orange.shade400, Colors.deepOrange.shade600],
            Icons.money_off,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientStatCard(String title, String value, List<Color> colors, IconData icon) {
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsStatusCard() {
    final remaining = totalBaseSalaries - totalWithdrawals;
    final progress = totalBaseSalaries > 0 ? totalWithdrawals / totalBaseSalaries : 0;

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.analytics_outlined, color: Colors.teal.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'salaries_withdrawals_status'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'withdrawals_progress'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
                    minHeight: 10,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatusBox(
                    'total_due'.tr,
                    settingsController.currencyFormatter(totalBaseSalaries),
                    Colors.indigo,
                    Icons.account_balance,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: _buildStatusBox(
                    'total_withdrawn'.tr,
                    settingsController.currencyFormatter(totalWithdrawals),
                    Colors.orange,
                    Icons.remove_circle,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: _buildStatusBox(
                    'remaining'.tr,
                    settingsController.currencyFormatter(remaining),
                    remaining >= 0 ? Colors.green : Colors.red,
                    Icons.savings,
                  ),
                ),
              ],
            ),

            if (totalBonuses > 0 || totalDeductions > 0) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (totalBonuses > 0)
                    Expanded(
                      child: _buildMiniStat(
                        'bonuses'.tr,
                        settingsController.currencyFormatter(totalBonuses),
                        Colors.green,
                        Icons.add_circle_outline,
                      ),
                    ),
                  if (totalBonuses > 0 && totalDeductions > 0)
                    const SizedBox(width: 16),
                  if (totalDeductions > 0)
                    Expanded(
                      child: _buildMiniStat(
                        'deductions'.tr,
                        settingsController.currencyFormatter(totalDeductions),
                        Colors.red,
                        Icons.remove_circle_outline,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesList() {
    if (employeeSummaries.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, color: Colors.grey.shade400, size: 48),
                const SizedBox(height: 16),
                Text('no_employees'.tr, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      );
    }

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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.people, color: Colors.teal.shade600, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'employees_list'.tr,
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
                    '${employees.length} ${'employee'.tr}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
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
            itemCount: employeeSummaries.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200, indent: 70),
            itemBuilder: (context, index) {
              final summary = employeeSummaries[index];
              final employee = summary['employee'] as Employee;
              return _buildEmployeeItem(employee, summary);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeItem(Employee employee, Map<String, dynamic> summary) {
    final netSalary = summary['netSalary'] as double;
    final remaining = summary['remaining'] as double;
    final withdrawals = summary['withdrawals'] as double;
    final bonuses = summary['bonuses'] as double;
    final deductions = summary['deductions'] as double;
    final transactionCount = summary['transactionCount'] as int;

    final progress = employee.salary > 0 ? withdrawals / employee.salary : 0;

    Color statusColor;
    IconData statusIcon;
    switch (employee.status) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'vacation':
        statusColor = Colors.orange;
        statusIcon = Icons.beach_access;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.person;
    }

    return InkWell(
      onTap: () => Get.to(() => EmployeeReportPage(employee: employee)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade300, Colors.teal.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      employee.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(statusIcon, color: statusColor, size: 12),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        employee.jobTitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Mini progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress > 0.8 ? Colors.red.shade400 : Colors.orange.shade400,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      settingsController.currencyFormatter(netSalary),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (withdrawals > 0)
                      Text(
                        '-${settingsController.currencyFormatter(withdrawals)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    if (transactionCount > 0)
                      Text(
                        '$transactionCount ${'transactions'.tr}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_left, color: Colors.grey.shade400, size: 18),
              ],
            ),
          ],
        ),
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
      loadData();
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
                    pw.Text('employees_report'.tr, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '${'period'.tr}: ${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['item'.tr, 'value'.tr],
              data: [
                ['total_due_salaries'.tr, settingsController.currencyFormatter(totalBaseSalaries)],
                ['total_withdrawn'.tr, settingsController.currencyFormatter(totalWithdrawals)],
                ['remaining'.tr, settingsController.currencyFormatter(totalBaseSalaries - totalWithdrawals)],
                ['bonuses'.tr, settingsController.currencyFormatter(totalBonuses)],
                ['deductions'.tr, settingsController.currencyFormatter(totalDeductions)],
                ['net_total'.tr, settingsController.currencyFormatter(totalNetSalaries)],
                ['employees'.tr, employees.length.toString()],
                ['transactions_count'.tr, totalTransactions.toString()],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
              cellAlignment: pw.Alignment.centerRight,
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            if (employeeSummaries.isNotEmpty) ...[
              pw.Header(level: 1, text: 'employees_details'.tr),
              pw.Table.fromTextArray(
                headers: ['name'.tr, 'job'.tr, 'base_salary'.tr, 'withdrawn'.tr, 'remaining'.tr, 'net'.tr],
                data: employeeSummaries.map((summary) {
                  final emp = summary['employee'] as Employee;
                  final remaining = summary['remaining'] as double;
                  return [
                    emp.name,
                    emp.jobTitle,
                    settingsController.currencyFormatter(emp.salary),
                    settingsController.currencyFormatter(summary['withdrawals'] as double),
                    settingsController.currencyFormatter(remaining),
                    settingsController.currencyFormatter(summary['netSalary'] as double),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerRight,
                cellStyle: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ],
        ),
      );

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/employees_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      await Printing.sharePdf(bytes: bytes, filename: 'employees_report.pdf');
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        '${'export_error'.tr}: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
