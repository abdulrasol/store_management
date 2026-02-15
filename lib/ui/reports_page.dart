import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/expense.dart';
import 'package:store_management/models/purchase.dart';
import 'package:store_management/models/salary.dart';
import 'package:store_management/models/invoice.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  final DatabaseController databaseController = Get.find<DatabaseController>();
  final SettingsController settingsController = Get.find<SettingsController>();
  
  late TabController _tabController;
  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  bool isLoading = false;
  
  // Data
  double totalSales = 0;
  double totalPurchases = 0;
  double totalExpenses = 0;
  double totalSalaries = 0;
  double netProfit = 0;
  
  List<Purchase> filteredPurchases = [];
  List<Expense> filteredExpenses = [];
  List<Salary> filteredSalaries = [];
  List<Invoice> filteredSales = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    // 2. Purchases
    final allPurchases = await databaseController.getPurchases();
    filteredPurchases = allPurchases.where((p) {
      return p.purchaseDate.isAfter(start) && p.purchaseDate.isBefore(end);
    }).toList();
    totalPurchases = filteredPurchases.fold(0, (sum, item) => sum + item.totalAmount);

    // 3. Expenses
    final allExpenses = databaseController.expenses;
    filteredExpenses = allExpenses.where((e) {
      return e.date.isAfter(start) && e.date.isBefore(end);
    }).toList();
    totalExpenses = filteredExpenses.fold(0, (sum, item) => sum + item.amount);

    // 4. Salaries
    // Note: Salaries are usually monthly. We verify if the month is within range.
    final allSalaries = await databaseController.getSalaries();
    filteredSalaries = allSalaries.where((s) {
      return s.month.isAfter(start.subtract(const Duration(days: 1))) && 
             s.month.isBefore(end.add(const Duration(days: 1)));
    }).toList();
    totalSalaries = filteredSalaries.fold(0, (sum, item) => sum + item.totalSalary);

    // Net Profit
    netProfit = totalSales - totalPurchases - totalExpenses - totalSalaries;

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('التقارير المالية'.tr),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'الملخص'.tr),
            Tab(text: 'المصروفات والمشتريات'.tr),
            Tab(text: 'المبيعات والرواتب'.tr),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickDateRange,
            tooltip: 'تحديد الفترة'.tr,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
            tooltip: 'تصدير PDF'.tr,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildExpensesPurchasesTab(),
                _buildSalesSalariesTab(),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDateHeader(),
          const SizedBox(height: 20),
          _buildSummaryCard('المبيعات'.tr, totalSales, Colors.green, Icons.attach_money),
          _buildSummaryCard('المشتريات'.tr, totalPurchases, Colors.blue, Icons.shopping_cart),
          _buildSummaryCard('المصروفات'.tr, totalExpenses, Colors.orange, Icons.money_off),
          _buildSummaryCard('الرواتب'.tr, totalSalaries, Colors.purple, Icons.people),
          const Divider(height: 30, thickness: 2),
          _buildSummaryCard(
            'صافي الربح'.tr, 
            netProfit, 
            netProfit >= 0 ? Colors.teal : Colors.red, 
            netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
            isLarge: true
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesPurchasesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('توزيع المصروفات'.tr),
        if (filteredExpenses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('لا توجد بيانات'.tr, style: const TextStyle(color: Colors.grey)),
            ),
          )
        else
          ..._buildExpensesList(),
          
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        
        _buildSectionHeader('آخر المشتريات'.tr),
        ...filteredPurchases.take(10).map((p) => ListTile(
          leading: const Icon(Icons.shopping_bag, color: Colors.blue),
          title: Text(p.supplierName ?? 'بدون مورد'.tr), 
          subtitle: Text(DateFormat('yyyy-MM-dd').format(p.purchaseDate)),
          trailing: Text(
            settingsController.currencyFormatter(p.totalAmount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        )),
      ],
    );
  }

  List<Widget> _buildExpensesList() {
    // Group expenses by description/type
    Map<String, double> grouped = {};
    for (var e in filteredExpenses) {
      grouped[e.description] = (grouped[e.description] ?? 0) + e.amount;
    }
    
    // Sort by amount descending
    var sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double total = grouped.values.fold(0, (sum, val) => sum + val);

    return sortedEntries.map((entry) {
      double percentage = total == 0 ? 0 : (entry.value / total);
      return Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: const Icon(Icons.money_off, color: Colors.orange, size: 18),
            ),
            title: Text(entry.key),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  settingsController.currencyFormatter(entry.value),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
          ),
          const SizedBox(height: 8),
        ],
      );
    }).toList();
  }

  Widget _buildSalesSalariesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('أداء المبيعات'.tr),
        // Add chart or list here
        _buildStatRow('عدد الفواتير'.tr, filteredSales.length.toString()),
        _buildStatRow('متوسط قيمة الفاتورة'.tr, 
          filteredSales.isEmpty ? '0' : settingsController.currencyFormatter(totalSales / filteredSales.length)),
        
        const SizedBox(height: 20),
        _buildSectionHeader('رواتب الموظفين'.tr),
        ...filteredSalaries.map((s) => ListTile(
          leading: const Icon(Icons.person, color: Colors.purple),
          title: Text(s.employeeName),
          subtitle: Text(DateFormat('MMMM yyyy').format(s.month)),
          trailing: Text(
            settingsController.currencyFormatter(s.totalSalary),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        )),
      ],
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon, {bool isLarge = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: isLarge ? 32 : 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text(
                    settingsController.currencyFormatter(amount),
                    style: TextStyle(
                      fontSize: isLarge ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      color: isLarge ? color : Colors.black87,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
    final pdf = pw.Document();
    
    // Load font
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final ttfBold = pw.Font.ttf(boldFontData);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Center(child: pw.Text('التقرير المالي التفصيلي', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          ),
          pw.Paragraph(
            text: 'الفترة: ${DateFormat('yyyy-MM-dd').format(dateRange.start)} إلى ${DateFormat('yyyy-MM-dd').format(dateRange.end)}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 20),
          
          // Summary Table
          pw.Table.fromTextArray(
            headers: ['البند', 'القيمة'],
            data: [
              ['المبيعات', settingsController.currencyFormatter(totalSales)],
              ['المشتريات', settingsController.currencyFormatter(totalPurchases)],
              ['المصروفات', settingsController.currencyFormatter(totalExpenses)],
              ['الرواتب', settingsController.currencyFormatter(totalSalaries)],
              ['صافي الربح', settingsController.currencyFormatter(netProfit)],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            cellAlignment: pw.Alignment.centerRight,
          ),
          
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'تفاصيل المصروفات'),
          pw.Table.fromTextArray(
            headers: ['التاريخ', 'الوصف', 'المبلغ'],
            data: filteredExpenses.map((e) => [
              DateFormat('yyyy-MM-dd').format(e.date),
              e.description,
              settingsController.currencyFormatter(e.amount),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerRight,
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    
    await Printing.sharePdf(bytes: bytes, filename: 'report.pdf');
  }
}