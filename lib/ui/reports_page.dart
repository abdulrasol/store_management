import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/expense.dart';
import 'package:store_management/models/purchase.dart';
import 'package:store_management/models/salary.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  final DatabaseController databaseController = Get.find<DatabaseController>();
  final SettingsController settingsController = Get.find<SettingsController>();
  
  late TabController _tabController;
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime endDate = DateTime.now();
  bool isLoading = false;

  // Report Data
  List<Purchase> purchases = [];
  List<Salary> salaries = [];
  List<Expense> expenses = [];
  double totalSales = 0;
  double totalPurchases = 0;
  double totalSalaries = 0;
  double totalExpenses = 0;
  double netProfit = 0;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'ar_AE',
    symbol: 'AED ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadAllData() async {
    setState(() => isLoading = true);
    
    try {
      // Load purchases
      purchases = await databaseController.getPurchases(
        startDate: startDate,
        endDate: endDate,
      );
      totalPurchases = purchases.fold(0, (sum, p) => sum + p.totalAmount);

      // Load salaries
      salaries = await databaseController.getSalariesByMonth(startDate);
      // Filter by date range
      salaries = salaries.where((s) => 
        s.month.isAfter(startDate.subtract(const Duration(days: 1))) &&
        s.month.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();
      totalSalaries = salaries.fold(0, (sum, s) => sum + s.totalSalary);

      // Load expenses
      expenses = databaseController.getFilteriedExpenses(startDate);
      // Filter by end date
      expenses = expenses.where((e) => 
        e.date.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();
      totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);

      // Get sales from existing controller
      totalSales = databaseController.getSales(startDate, endDate);

      // Calculate net profit
      netProfit = totalSales - totalPurchases - totalExpenses - totalSalaries;

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('خطأ'.tr, 'فشل تحميل التقارير'.tr);
    }
  }

  void _selectDateRange() async {
    final pickedStart = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'اختر تاريخ البداية'.tr,
    );

    if (pickedStart != null) {
      final pickedEnd = await showDatePicker(
        context: context,
        initialDate: endDate,
        firstDate: pickedStart,
        lastDate: DateTime.now(),
        helpText: 'اختر تاريخ النهاية'.tr,
      );

      if (pickedEnd != null) {
        setState(() {
          startDate = pickedStart;
          endDate = pickedEnd;
        });
        loadAllData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('التقارير'.tr),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.dashboard), text: 'الملخص'.tr),
            Tab(icon: const Icon(Icons.shopping_cart), text: 'المشتريات'.tr),
            Tab(icon: const Icon(Icons.payments), text: 'الرواتب'.tr),
            Tab(icon: const Icon(Icons.receipt_long), text: 'المصروفات'.tr),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'اختيار الفترة'.tr,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
            tooltip: 'تصدير PDF'.tr,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
            tooltip: 'مشاركة'.tr,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildPurchasesTab(),
                _buildSalariesTab(),
                _buildExpensesTab(),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Header
          Card(
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الفترة'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Summary Cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSummaryCard(
                'إجمالي المبيعات'.tr,
                totalSales,
                Colors.teal,
                Icons.trending_up,
              ),
              _buildSummaryCard(
                'إجمالي المشتريات'.tr,
                totalPurchases,
                Colors.blue,
                Icons.shopping_cart,
              ),
              _buildSummaryCard(
                'إجمالي الرواتب'.tr,
                totalSalaries,
                Colors.orange,
                Icons.people,
              ),
              _buildSummaryCard(
                'إجمالي المصروفات'.tr,
                totalExpenses,
                Colors.red,
                Icons.receipt_long,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Net Profit Card
          Card(
            color: netProfit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: netProfit >= 0 ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'صافي الربح'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: netProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currencyFormat.format(netProfit),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: netProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Breakdown Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفصيل الحساب'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTableRow('المبيعات'.tr, totalSales, Colors.teal),
                  const Divider(),
                  _buildTableRow('المشتريات'.tr, -totalPurchases, Colors.blue),
                  _buildTableRow('الرواتب'.tr, -totalSalaries, Colors.orange),
                  _buildTableRow('المصروفات'.tr, -totalExpenses, Colors.red),
                  const Divider(thickness: 2),
                  _buildTableRow('صافي الربح'.tr, netProfit, 
                    netProfit >= 0 ? Colors.green : Colors.red, isBold: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color, IconData icon) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 22,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(value),
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
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            currencyFormat.format(value),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: isBold ? color : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasesTab() {
    return Column(
      children: [
        // Total Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '${'إجمالي المشتريات:'.tr} ${currencyFormat.format(totalPurchases)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: purchases.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد مشتريات في هذه الفترة'.tr,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    final p = purchases[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(p.supplierName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.receiptNumber} - ${DateFormat('yyyy-MM-dd').format(p.purchaseDate)}'),
                        trailing: Text(
                          currencyFormat.format(p.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSalariesTab() {
    return Column(
      children: [
        // Total Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.orange.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '${'إجمالي الرواتب:'.tr} ${currencyFormat.format(totalSalaries)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: salaries.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد رواتب في هذه الفترة'.tr,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: salaries.length,
                  itemBuilder: (context, index) {
                    final s = salaries[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(s.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('MMMM yyyy', 'ar').format(s.month)),
                        trailing: Text(
                          currencyFormat.format(s.totalSalary),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExpensesTab() {
    return Column(
      children: [
        // Total Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.red.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                '${'إجمالي المصروفات:'.tr} ${currencyFormat.format(totalExpenses)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: expenses.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد مصروفات في هذه الفترة'.tr,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final e = expenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('yyyy-MM-dd').format(e.date)),
                        trailing: Text(
                          currencyFormat.format(e.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'مطبعة الروعة',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'تقرير مالي',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'الفترة: ${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildPDFRow('المبيعات', totalSales),
                    _buildPDFRow('المشتريات', -totalPurchases),
                    _buildPDFRow('الرواتب', -totalSalaries),
                    _buildPDFRow('المصروفات', -totalExpenses),
                    pw.Divider(thickness: 2),
                    _buildPDFRow(
                      'صافي الربح',
                      netProfit,
                      isBold: true,
                      color: netProfit >= 0 ? PdfColors.green : PdfColors.red,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Purchases Details
              if (purchases.isNotEmpty) ...[
                pw.Text(
                  'تفاصيل المشتريات',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['المورد', 'رقم الفاتورة', 'التاريخ', 'المبلغ'],
                  data: purchases.map((p) => [
                    p.supplierName,
                    p.receiptNumber,
                    DateFormat('yyyy-MM-dd').format(p.purchaseDate),
                    currencyFormat.format(p.totalAmount),
                  ]).toList(),
                ),
                pw.SizedBox(height: 20),
              ],

              // Salaries Details
              if (salaries.isNotEmpty) ...[
                pw.Text(
                  'تفاصيل الرواتب',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['الموظف', 'الشهر', 'الراتب الأساسي', 'الإجمالي'],
                  data: salaries.map((s) => [
                    s.employeeName,
                    DateFormat('MMMM yyyy', 'ar').format(s.month),
                    currencyFormat.format(s.baseSalary),
                    currencyFormat.format(s.totalSalary),
                  ]).toList(),
                ),
                pw.SizedBox(height: 20),
              ],

              // Expenses Details
              if (expenses.isNotEmpty) ...[
                pw.Text(
                  'تفاصيل المصروفات',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['البيان', 'التاريخ', 'المبلغ'],
                  data: expenses.map((e) => [
                    e.description,
                    DateFormat('yyyy-MM-dd').format(e.date),
                    currencyFormat.format(e.amount),
                  ]).toList(),
                ),
              ],

              // Footer
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'تم إنشاء هذا التقرير في ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPDFRow(String label, double value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            currencyFormat.format(value),
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _shareReport() {
    final StringBuffer report = StringBuffer();
    
    report.writeln('📊 تقرير مالي - مطبعة الروعة');
    report.writeln('📅 الفترة: ${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}');
    report.writeln('');
    report.writeln('📈 المبيعات: ${currencyFormat.format(totalSales)}');
    report.writeln('🛒 المشتريات: ${currencyFormat.format(totalPurchases)}');
    report.writeln('👥 الرواتب: ${currencyFormat.format(totalSalaries)}');
    report.writeln('💸 المصروفات: ${currencyFormat.format(totalExpenses)}');
    report.writeln('━' * 20);
    report.writeln('${netProfit >= 0 ? "✅" : "❌"} صافي الربح: ${currencyFormat.format(netProfit)}');

    Share.share(report.toString(), subject: 'تقرير مالي - مطبعة الروعة');
  }
}
