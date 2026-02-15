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
      
      // Calculations
      totalSalary = widget.employee.salary; // Base Salary (assuming monthly)
      
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${'report'.tr}: ${widget.employee.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDateHeader(),
            const SizedBox(height: 20),
            _buildSummaryCard(),
            const SizedBox(height: 20),
            const Divider(),
            _buildSectionHeader('transactions'.tr),
            const SizedBox(height: 10),
            if (transactions.isEmpty)
              Center(child: Text('no_data'.tr, style: const TextStyle(color: Colors.grey)))
            else
              ...transactions.map((t) => _buildTransactionItem(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${DateFormat('yyyy-MM-dd').format(dateRange.start)} - ${DateFormat('yyyy-MM-dd').format(dateRange.end)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow('basic_salary'.tr, totalSalary, Colors.blue),
            _buildSummaryRow('bonuses'.tr, totalBonuses, Colors.green),
            _buildSummaryRow('withdrawals'.tr, totalWithdrawals, Colors.orange),
            _buildSummaryRow('deductions'.tr, totalDeductions, Colors.red),
            const Divider(),
            _buildSummaryRow('net_salary'.tr, netSalary, Colors.teal, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: isBold ? 18 : 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(SalaryTransaction t) {
    Color color = Colors.grey;
    IconData icon = Icons.info;
    String typeLabel = t.type;

    if (t.type == 'withdraw') {
      color = Colors.orange;
      icon = Icons.money_off; 
      typeLabel = 'withdraw'.tr;
    } else if (t.type == 'deduction') {
      color = Colors.red;
      icon = Icons.remove_circle_outline;
      typeLabel = 'deduction'.tr;
    } else if (t.type == 'bonus') {
      color = Colors.green;
      icon = Icons.add_circle_outline;
      typeLabel = 'bonus'.tr;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('yyyy-MM-dd').format(t.date)),
        trailing: Text(
          t.amount.toStringAsFixed(2),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      
      // Load fonts
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
                  pw.Text('${DateFormat('yyyy-MM-dd').format(dateRange.start)} - ${DateFormat('yyyy-MM-dd').format(dateRange.end)}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Stats Table
            pw.Table.fromTextArray(
              headers: ['item'.tr, 'value'.tr],
              data: [
                ['basic_salary'.tr, totalSalary.toStringAsFixed(2)],
                ['bonuses'.tr, totalBonuses.toStringAsFixed(2)],
                ['withdrawals'.tr, totalWithdrawals.toStringAsFixed(2)],
                ['deductions'.tr, totalDeductions.toStringAsFixed(2)],
                ['net_salary'.tr, netSalary.toStringAsFixed(2)],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
              cellAlignment: pw.Alignment.centerRight,
            ),
            
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'details'.tr),
            
            pw.Table.fromTextArray(
              headers: ['date'.tr, 'type'.tr, 'amount'.tr],
              data: transactions.map((t) {
                String type = t.type;
                if(type == 'withdraw') type = 'withdraw'.tr;
                if(type == 'deduction') type = 'deduction'.tr;
                if(type == 'bonus') type = 'bonus'.tr;
                
                return [
                  DateFormat('yyyy-MM-dd').format(t.date),
                  type,
                  t.amount.toStringAsFixed(2),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerRight,
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
