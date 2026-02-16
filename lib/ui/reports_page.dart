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
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/employee.dart';
import 'package:store_management/models/expense.dart';
import 'package:store_management/models/invoice.dart';
import 'package:store_management/models/purchase.dart';
import 'package:store_management/ui/reports/purchase_report_page.dart';
import 'package:store_management/ui/reports/expense_report_page.dart';
import 'package:store_management/ui/reports/employees_report_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final DatabaseController databaseController = Get.find<DatabaseController>();
  final SettingsController settingsController = Get.find<SettingsController>();

  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  bool isLoading = false;

  // Data
  double totalSales = 0;
  double totalPurchases = 0;
  double totalExpenses = 0;
  double netProfit = 0;

  List<Purchase> filteredPurchases = [];
  List<Expense> filteredExpenses = [];
  List<Invoice> filteredSales = [];
  List<Employee> employees = [];

  int totalInvoices = 0;
  int totalPurchasesCount = 0;
  int totalExpensesCount = 0;
  double avgPurchaseValue = 0;
  double avgExpenseValue = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    // Filter dates (inclusive)
    final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
    final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);

    // 1. Sales (Invoices)
    final allInvoices = databaseController.inovices;
    filteredSales = allInvoices.where((inv) {
      final date = DateTime.fromMillisecondsSinceEpoch(inv.date);
      return date.isAfter(start) && date.isBefore(end);
    }).toList();
    totalSales = filteredSales.fold(0, (sum, item) => sum + item.pricetoPay());
    totalInvoices = filteredSales.length;

    // 2. Purchases
    final allPurchases = await databaseController.getPurchases();
    filteredPurchases = allPurchases.where((p) {
      return p.purchaseDate.isAfter(start) && p.purchaseDate.isBefore(end);
    }).toList();
    totalPurchases = filteredPurchases.fold(0, (sum, item) => sum + item.totalAmount);
    totalPurchasesCount = filteredPurchases.length;
    avgPurchaseValue = totalPurchasesCount > 0 ? totalPurchases / totalPurchasesCount : 0;

    // 3. Expenses
    final allExpenses = databaseController.expenses;
    filteredExpenses = allExpenses.where((e) {
      return e.date.isAfter(start) && e.date.isBefore(end);
    }).toList();
    totalExpenses = filteredExpenses.fold(0, (sum, item) => sum + item.amount);
    totalExpensesCount = filteredExpenses.length;
    avgExpenseValue = totalExpensesCount > 0 ? totalExpenses / totalExpensesCount : 0;

    // 4. Employees
    employees = await databaseController.getEmployees();

    // Net Profit
    netProfit = totalSales - totalPurchases - totalExpenses;

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('reports'.tr),
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
                    _buildSummaryCardsRow(),
                    const SizedBox(height: 12),
                    _buildSecondaryCardsRow(),
                    const SizedBox(height: 16),
                    _buildQuickReportButtons(),
                    const SizedBox(height: 20),
                    _buildExpensesDistribution(),
                    const SizedBox(height: 20),
                    _buildRecentActivity(),
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
          colors: [Colors.blue.shade100, Colors.purple.shade100],
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
          Icon(Icons.date_range, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildCompactSummaryCard(
            'purchases'.tr,
            totalPurchases,
            Colors.blue,
            Icons.shopping_cart,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCompactSummaryCard(
            'expenses'.tr,
            totalExpenses,
            Colors.orange,
            Icons.money_off,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildCompactSummaryCard(
            'net_profit'.tr,
            netProfit,
            netProfit >= 0 ? Colors.teal : Colors.red,
            netProfit >= 0 ? Icons.account_balance : Icons.warning,
            isHighlighted: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCompactSummaryCard(
            'summary'.tr,
            totalPurchasesCount + totalExpensesCount.toDouble(),
            Colors.purple,
            Icons.summarize,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSummaryCard(String title, double amount, Color color, IconData icon, {bool isHighlighted = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isHighlighted ? null : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            settingsController.currencyFormatter(amount),
            style: TextStyle(
              fontSize: isHighlighted ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReportButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'detailed_reports'.tr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildReportButton(
                'purchases_report'.tr,
                Icons.shopping_cart_outlined,
                Colors.blue,
                () => Get.to(() => PurchaseReportPage(dateRange: dateRange)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildReportButton(
                'expenses_report'.tr,
                Icons.receipt_long_outlined,
                Colors.orange,
                () => Get.to(() => ExpenseReportPage(dateRange: dateRange)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildReportButton(
                'employees_report'.tr,
                Icons.people_outline,
                Colors.teal,
                () => Get.to(() => EmployeesReportPage(dateRange: dateRange)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildReportButton(
                'full_report'.tr,
                Icons.summarize_outlined,
                Colors.purple,
                _generatePdf,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesDistribution() {
    if (filteredExpenses.isEmpty) return const SizedBox.shrink();

    Map<String, double> grouped = {};
    for (var e in filteredExpenses) {
      grouped[e.description] = (grouped[e.description] ?? 0) + e.amount;
    }

    var sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double total = grouped.values.fold(0, (sum, val) => sum + val);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_outline, color: Colors.orange.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  'expenses_distribution'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sortedEntries.take(4).map((entry) {
              double percentage = total == 0 ? 0 : (entry.value / total);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (sortedEntries.length > 4)
              Center(
                child: TextButton(
                  onPressed: () => Get.to(() => ExpenseReportPage(dateRange: dateRange)),
                  child: Text(
                    'view_all'.tr,
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue.shade600, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'summary'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatItem(Icons.shopping_bag_outlined, 'purchases_count'.tr, totalPurchasesCount.toString(), Colors.blue),
            _buildStatItem(Icons.shopping_bag_outlined, 'purchases_count'.tr, totalPurchasesCount.toString(), Colors.green),
            _buildStatItem(Icons.receipt_long_outlined, 'expenses_count'.tr, totalExpensesCount.toString(), Colors.orange),
            _buildStatItem(Icons.trending_up, 'avg_purchase'.tr, settingsController.currencyFormatter(avgPurchaseValue), Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
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
                    pw.Text('financial_report'.tr, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
              headers: ['item'.tr, 'value'.tr, 'count'.tr],
              data: [
                ['sales'.tr, settingsController.currencyFormatter(totalSales), totalInvoices.toString()],
                ['purchases'.tr, settingsController.currencyFormatter(totalPurchases), totalPurchasesCount.toString()],
                ['expenses'.tr, settingsController.currencyFormatter(totalExpenses), totalExpensesCount.toString()],
                ['net_profit'.tr, settingsController.currencyFormatter(netProfit), ''],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
              cellAlignment: pw.Alignment.centerRight,
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            if (filteredExpenses.isNotEmpty) ...[
              pw.Header(level: 1, text: 'expenses_details'.tr),
              pw.Table.fromTextArray(
                headers: ['date'.tr, 'description'.tr, 'amount'.tr],
                data: filteredExpenses.take(20).map((e) => [
                  DateFormat('dd/MM/yyyy').format(e.date),
                  e.description,
                  settingsController.currencyFormatter(e.amount),
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerRight,
                cellStyle: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ],
        ),
      );

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      await Printing.sharePdf(bytes: bytes, filename: 'financial_report.pdf');
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
