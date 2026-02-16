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
import 'package:store_management/models/expense.dart';

class ExpenseReportPage extends StatefulWidget {
  final DateTimeRange dateRange;

  const ExpenseReportPage({super.key, required this.dateRange});

  @override
  State<ExpenseReportPage> createState() => _ExpenseReportPageState();
}

class _ExpenseReportPageState extends State<ExpenseReportPage> {
  final DatabaseController databaseController = Get.find<DatabaseController>();
  final SettingsController settingsController = Get.find<SettingsController>();

  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  bool isLoading = false;

  List<Expense> filteredExpenses = [];
  double totalExpenses = 0;
  int expensesCount = 0;
  double avgExpense = 0;
  double maxExpense = 0;
  double minExpense = 0;

  Map<String, double> categoryTotals = {};
  Map<String, int> categoryCounts = {};

  @override
  void initState() {
    super.initState();
    dateRange = widget.dateRange;
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
    final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);

    final allExpenses = databaseController.expenses;
    filteredExpenses = allExpenses.where((e) {
      return e.date.isAfter(start) && e.date.isBefore(end);
    }).toList();

    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

    totalExpenses = filteredExpenses.fold(0, (sum, item) => sum + item.amount);
    expensesCount = filteredExpenses.length;
    avgExpense = expensesCount > 0 ? totalExpenses / expensesCount : 0;

    if (filteredExpenses.isNotEmpty) {
      maxExpense = filteredExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
      minExpense = filteredExpenses.map((e) => e.amount).reduce((a, b) => a < b ? a : b);
    }

    // Group by category/description
    categoryTotals = {};
    categoryCounts = {};
    for (var e in filteredExpenses) {
      categoryTotals[e.description] = (categoryTotals[e.description] ?? 0) + e.amount;
      categoryCounts[e.description] = (categoryCounts[e.description] ?? 0) + 1;
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('expenses_report'.tr),
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
                    _buildSummaryCards(),
                    const SizedBox(height: 12),
                    _buildStatisticsCard(),
                    const SizedBox(height: 16),
                    _buildCategoriesDistribution(),
                    const SizedBox(height: 16),
                    _buildExpensesList(),
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
          colors: [Colors.orange.shade100, Colors.deepOrange.shade100],
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
          Icon(Icons.date_range, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildCompactStatCard(
            'total_expenses'.tr,
            settingsController.currencyFormatter(totalExpenses),
            Colors.orange,
            Icons.money_off,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCompactStatCard(
            'count'.tr,
            expensesCount.toString(),
            Colors.deepOrange,
            Icons.format_list_numbered,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
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
                Icon(Icons.analytics_outlined, color: Colors.orange.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  'statistics'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'avg_expense'.tr,
                    settingsController.currencyFormatter(avgExpense),
                    Icons.trending_flat,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'max_expense'.tr,
                    settingsController.currencyFormatter(maxExpense),
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'min_expense'.tr,
                    settingsController.currencyFormatter(minExpense),
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesDistribution() {
    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    var sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                  'categories_distribution'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sortedCategories.take(6).map((entry) {
              double percentage = totalExpenses > 0 ? (entry.value / totalExpenses) : 0;
              int count = categoryCounts[entry.key] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
                          settingsController.currencyFormatter(entry.value),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ${'transactions'.tr}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    if (filteredExpenses.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 48),
                const SizedBox(height: 16),
                Text('no_data'.tr, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.orange.shade600, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'expenses_list'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${filteredExpenses.length} ${'transactions'.tr}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredExpenses.length > 15 ? 15 : filteredExpenses.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final expense = filteredExpenses[index];
              return _buildExpenseItem(expense);
            },
          ),
          if (filteredExpenses.length > 15)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  '${'showing'.tr} 15 ${'of'.tr} ${filteredExpenses.length}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt, color: Colors.orange, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(expense.date),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            settingsController.currencyFormatter(expense.amount),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
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
            value,
            style: TextStyle(
              fontSize: 16,
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
                    pw.Text('expenses_report'.tr, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
                ['total_expenses'.tr, settingsController.currencyFormatter(totalExpenses)],
                ['count'.tr, expensesCount.toString()],
                ['avg_expense'.tr, settingsController.currencyFormatter(avgExpense)],
                ['max_expense'.tr, settingsController.currencyFormatter(maxExpense)],
                ['min_expense'.tr, settingsController.currencyFormatter(minExpense)],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange700),
              cellAlignment: pw.Alignment.centerRight,
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            if (filteredExpenses.isNotEmpty) ...[
              pw.Header(level: 1, text: 'expenses_details'.tr),
              pw.Table.fromTextArray(
                headers: ['date'.tr, 'description'.tr, 'amount'.tr],
                data: filteredExpenses.map((e) => [
                  DateFormat('dd/MM/yyyy HH:mm').format(e.date),
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
      final file = File('${dir.path}/expenses_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      await Printing.sharePdf(bytes: bytes, filename: 'expenses_report.pdf');
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
