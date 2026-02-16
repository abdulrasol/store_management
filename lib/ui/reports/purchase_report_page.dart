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
import 'package:store_management/models/purchase.dart';

class PurchaseReportPage extends StatefulWidget {
  final DateTimeRange dateRange;

  const PurchaseReportPage({super.key, required this.dateRange});

  @override
  State<PurchaseReportPage> createState() => _PurchaseReportPageState();
}

class _PurchaseReportPageState extends State<PurchaseReportPage> {
  final DatabaseController databaseController = Get.find<DatabaseController>();
  final SettingsController settingsController = Get.find<SettingsController>();

  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  bool isLoading = false;

  List<Purchase> filteredPurchases = [];
  double totalPurchases = 0;
  double totalPaid = 0;
  double totalUnpaid = 0;
  double totalPartial = 0;
  int purchasesCount = 0;
  double avgPurchase = 0;

  Map<String, double> supplierTotals = {};
  Map<String, int> paymentStatusCounts = {};

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

    final allPurchases = await databaseController.getPurchases();
    filteredPurchases = allPurchases.where((p) {
      return p.purchaseDate.isAfter(start) && p.purchaseDate.isBefore(end);
    }).toList();

    filteredPurchases.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    totalPurchases = filteredPurchases.fold(0, (sum, item) => sum + item.totalAmount);
    purchasesCount = filteredPurchases.length;
    avgPurchase = purchasesCount > 0 ? totalPurchases / purchasesCount : 0;

    // Calculate payment status
    totalPaid = filteredPurchases
        .where((p) => p.paymentStatus == 'paid')
        .fold(0, (sum, p) => sum + p.totalAmount);

    totalUnpaid = filteredPurchases
        .where((p) => p.paymentStatus == 'unpaid')
        .fold(0, (sum, p) => sum + p.totalAmount);

    totalPartial = filteredPurchases
        .where((p) => p.paymentStatus == 'partial')
        .fold(0, (sum, p) => sum + p.totalAmount);

    // Group by supplier
    supplierTotals = {};
    for (var p in filteredPurchases) {
      supplierTotals[p.supplierName] = (supplierTotals[p.supplierName] ?? 0) + p.totalAmount;
    }

    // Payment status counts
    paymentStatusCounts = {
      'paid': filteredPurchases.where((p) => p.paymentStatus == 'paid').length,
      'unpaid': filteredPurchases.where((p) => p.paymentStatus == 'unpaid').length,
      'partial': filteredPurchases.where((p) => p.paymentStatus == 'partial').length,
    };

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('purchases_report'.tr),
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
                    _buildPaymentStatusCard(),
                    const SizedBox(height: 16),
                    _buildTopSuppliers(),
                    const SizedBox(height: 16),
                    _buildPurchasesList(),
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
          colors: [Colors.blue.shade100, Colors.indigo.shade100],
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

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildCompactStatCard(
            'total_purchases'.tr,
            settingsController.currencyFormatter(totalPurchases),
            Colors.blue,
            Icons.shopping_cart,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCompactStatCard(
            'count'.tr,
            purchasesCount.toString(),
            Colors.indigo,
            Icons.format_list_numbered,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusCard() {
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
                Icon(Icons.payment_outlined, color: Colors.blue.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  'payment_status'.tr,
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
                  child: _buildPaymentStatusItem(
                    'paid'.tr,
                    settingsController.currencyFormatter(totalPaid),
                    paymentStatusCounts['paid'] ?? 0,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildPaymentStatusItem(
                    'unpaid'.tr,
                    settingsController.currencyFormatter(totalUnpaid),
                    paymentStatusCounts['unpaid'] ?? 0,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildPaymentStatusItem(
                    'partial'.tr,
                    settingsController.currencyFormatter(totalPartial),
                    paymentStatusCounts['partial'] ?? 0,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusItem(String label, String amount, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            label == 'paid'.tr
                ? Icons.check_circle
                : label == 'unpaid'.tr
                    ? Icons.cancel
                    : Icons.watch_later,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$count ${'bills'.tr}',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopSuppliers() {
    if (supplierTotals.isEmpty) return const SizedBox.shrink();

    var sortedSuppliers = supplierTotals.entries.toList()
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
                Icon(Icons.people_outline, color: Colors.indigo.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  'top_suppliers'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sortedSuppliers.take(5).map((entry) {
              double percentage = totalPurchases > 0 ? (entry.value / totalPurchases) : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      settingsController.currencyFormatter(entry.value),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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

  Widget _buildPurchasesList() {
    if (filteredPurchases.isEmpty) {
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
                Icon(Icons.shopping_cart_outlined, color: Colors.grey.shade400, size: 48),
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
              children: [
                Icon(Icons.list_alt, color: Colors.blue.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  'purchases_list'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredPurchases.length > 10 ? 10 : filteredPurchases.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final purchase = filteredPurchases[index];
              return _buildPurchaseItem(purchase);
            },
          ),
          if (filteredPurchases.length > 10)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    '${'showing'.tr} 10 ${'of'.tr} ${filteredPurchases.length}',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPurchaseItem(Purchase purchase) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (purchase.paymentStatus) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'paid'.tr;
        break;
      case 'unpaid':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusLabel = 'unpaid'.tr;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.watch_later;
        statusLabel = 'partial'.tr;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag, color: Colors.blue, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.supplierName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${'bill'.tr}: ${purchase.receiptNumber}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                settingsController.currencyFormatter(purchase.totalAmount),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 10),
                  const SizedBox(width: 2),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
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
                    pw.Text('purchases_report'.tr, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
                ['total_purchases'.tr, settingsController.currencyFormatter(totalPurchases)],
                ['count'.tr, purchasesCount.toString()],
                ['avg_purchase'.tr, settingsController.currencyFormatter(avgPurchase)],
                ['paid'.tr, settingsController.currencyFormatter(totalPaid)],
                ['unpaid'.tr, settingsController.currencyFormatter(totalUnpaid)],
                ['partial'.tr, settingsController.currencyFormatter(totalPartial)],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
              cellAlignment: pw.Alignment.centerRight,
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            if (filteredPurchases.isNotEmpty) ...[
              pw.Header(level: 1, text: 'purchases_details'.tr),
              pw.Table.fromTextArray(
                headers: ['date'.tr, 'supplier'.tr, 'bill'.tr, 'amount'.tr, 'status'.tr],
                data: filteredPurchases.map((p) {
                  String status = p.paymentStatus;
                  if (status == 'paid') status = 'paid'.tr;
                  if (status == 'unpaid') status = 'unpaid'.tr;
                  if (status == 'partial') status = 'partial'.tr;

                  return [
                    DateFormat('dd/MM/yyyy').format(p.purchaseDate),
                    p.supplierName,
                    p.receiptNumber,
                    settingsController.currencyFormatter(p.totalAmount),
                    status,
                  ];
                }).toList(),
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
      final file = File('${dir.path}/purchases_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      await Printing.sharePdf(bytes: bytes, filename: 'purchases_report.pdf');
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
