import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:intl/intl.dart';

class DashboardPage extends GetView<DatabaseController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics Dashboard'.tr),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdvancedChart(context),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopSellingItems(context),
                const SizedBox(height: 16),
                _buildLowStockAlerts(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Chart State ---
  // Using generic Getx Controller logic embedded or simple local state wrapper?
  // Since DashboardPage is Stateless, let's use a local controller or Rx variables if we can bind them.
  // We can't really add properties to a stateless widget that persist.
  // Let's create a small controller for this page or use Rx variables in valid scope.
  // We can attach these Rx variables to the DatabaseController or just create them here
  // but they will reset on rebuild if not careful.
  // Best practice: Create a controller or use Get.put.
  // For simplicity, let's use a nested GetBuilder or just Rx variables if this page is persistent.
  // Let's assume this page is recreated. We'll use a local controller that Get finds.

  // Actually, we can just put the state in a small ChartController class here.
}

class DashboardChartController extends GetxController {
  final selectedPeriod = 'Week'.obs;
  final showSales = true.obs;
  final showProfits = true.obs;
  final showExpenses = false.obs; // Default hidden to avoid clutter? Or true? Let's say true.
}

Widget _buildAdvancedChart(BuildContext context) {
  final chartController = Get.put(DashboardChartController());
  final dbController = Get.find<DatabaseController>();
  final settingsController = Get.find<SettingsController>();

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Period Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Performance'.tr, style: Theme.of(context).textTheme.titleLarge),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _chartToggleButton(chartController, 'Week'),
                    _chartToggleButton(chartController, 'Month'),
                    _chartToggleButton(chartController, 'Year'),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          // Visibility Toggles
          Obx(() => Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text('Sales'.tr),
                    selected: chartController.showSales.value,
                    onSelected: (v) => chartController.showSales.value = v,
                    selectedColor: Colors.teal.withValues(alpha: 0.2),
                    checkmarkColor: Colors.teal,
                    labelStyle: TextStyle(color: chartController.showSales.value ? Colors.teal : Colors.grey),
                  ),
                  FilterChip(
                    label: Text('Profits'.tr),
                    selected: chartController.showProfits.value,
                    onSelected: (v) => chartController.showProfits.value = v,
                    selectedColor: Colors.green.withValues(alpha: 0.2),
                    checkmarkColor: Colors.green,
                    labelStyle: TextStyle(color: chartController.showProfits.value ? Colors.green : Colors.grey),
                  ),
                  FilterChip(
                    label: Text('Expenses'.tr),
                    selected: chartController.showExpenses.value,
                    onSelected: (v) => chartController.showExpenses.value = v,
                    selectedColor: Colors.red.withValues(alpha: 0.2),
                    checkmarkColor: Colors.red,
                    labelStyle: TextStyle(color: chartController.showExpenses.value ? Colors.red : Colors.grey),
                  ),
                ],
              )),
          const SizedBox(height: 24),
          // Chart
          AspectRatio(
            aspectRatio: 1.5,
            child: Obx(() {
              // Fetch Data based on Period
              Map<DateTime, double> salesData = {};
              Map<DateTime, double> profitsData = {};
              Map<DateTime, double> expensesData = {};

              String period = chartController.selectedPeriod.value;

              if (period == 'Week') {
                salesData = dbController.getWeeklySales();
                profitsData = dbController.getWeeklyProfits();
                expensesData = dbController.getWeeklyExpenses();
              } else if (period == 'Month') {
                salesData = dbController.getMonthlySales();
                profitsData = dbController.getMonthlyProfits();
                expensesData = dbController.getMonthlyExpenses();
              } else {
                // Year
                salesData = dbController.getYearlySales();
                profitsData = dbController.getYearlyProfits();
                expensesData = dbController.getYearlyExpenses();
              }

              // Normalize Dates to X-Axis Index
              // Union of all dates, sorted
              Set<DateTime> allDates = {};
              if (chartController.showSales.value) allDates.addAll(salesData.keys);
              if (chartController.showProfits.value) allDates.addAll(profitsData.keys);
              if (chartController.showExpenses.value) allDates.addAll(expensesData.keys);

              if (allDates.isEmpty) return Center(child: Text('No data'.tr));

              final sortedDates = allDates.toList()..sort();

              // Prepare Spots
              List<FlSpot> salesSpots = [];
              List<FlSpot> profitsSpots = [];
              List<FlSpot> expensesSpots = [];

              for (int i = 0; i < sortedDates.length; i++) {
                final date = sortedDates[i];
                if (chartController.showSales.value) salesSpots.add(FlSpot(i.toDouble(), salesData[date] ?? 0));
                if (chartController.showProfits.value) profitsSpots.add(FlSpot(i.toDouble(), profitsData[date] ?? 0));
                if (chartController.showExpenses.value) expensesSpots.add(FlSpot(i.toDouble(), expensesData[date] ?? 0));
              }

              double maxY = 100;
              final allValues = [...salesSpots, ...profitsSpots, ...expensesSpots].map((e) => e.y);
              if (allValues.isNotEmpty) {
                double calculatedMax = allValues.reduce((a, b) => a > b ? a : b);
                if (calculatedMax > 0) {
                  maxY = calculatedMax * 1.2;
                }
              }

              return LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey.withValues(alpha: 0.9),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final style = TextStyle(
                            color: spot.bar.color ?? Colors.white,
                            fontWeight: FontWeight.bold,
                          );
                          // String label = ''; // Removed unused variable
                          // if (spot.barIndex == 0 && chartController.showSales.value) label = 'Sales';
                          // This logic depends on order of lines added.
                          // Better: check color or pass data. Use loop index?
                          // The 'touchedSpots' order generally matches lineBarsData order.

                          // But we conditionally add lines.
                          // Let's just show value.
                          return LineTooltipItem(
                            settingsController.currencyFormatter(spot.y),
                            style,
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 5),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= sortedDates.length) return const SizedBox.shrink();

                          DateTime date = sortedDates[index];
                          String text = '';
                          if (period == 'Week') {
                            text = DateFormat('E').format(date); // Mon, Tue...
                          } else if (period == 'Month') {
                            if (index % 5 == 0) text = '${date.day}';
                          } else {
                            // Year
                            text = DateFormat('MMM').format(date);
                          }
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(text, style: const TextStyle(fontSize: 10)));
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    if (chartController.showSales.value)
                      LineChartBarData(
                        spots: salesSpots,
                        isCurved: true,
                        color: Colors.teal,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: Colors.teal.withValues(alpha: 0.1)),
                      ),
                    if (chartController.showProfits.value)
                      LineChartBarData(
                        spots: profitsSpots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.1)),
                      ),
                    if (chartController.showExpenses.value)
                      LineChartBarData(
                        spots: expensesSpots,
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: Colors.red.withValues(alpha: 0.1)),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    ),
  );
}

Widget _chartToggleButton(DashboardChartController controller, String text) {
  return Obx(() {
    bool isActive = controller.selectedPeriod.value == text;
    return GestureDetector(
      onTap: () => controller.selectedPeriod.value = text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
        ),
        child: Text(text.tr,
            style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black : Colors.grey)),
      ),
    );
  });
}

Widget _buildTopSellingItems(BuildContext context) {
  final controller = Get.find<DatabaseController>();
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Selling Items'.tr,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final topItems = controller.getTopSellingItems();
            if (topItems.isEmpty) {
              return Text('No sales yet'.tr);
            }
            return Column(
              children: topItems.map((item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.star, color: Colors.white, size: 16),
                  ),
                  title: Text(item['name'], style: const TextStyle(fontSize: 14)),
                  trailing: Text('${item['count']} ${'sold'.tr}', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
            );
          }),
        ],
      ),
    ),
  );
}

Widget _buildLowStockAlerts(BuildContext context) {
  final controller = Get.find<DatabaseController>();
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Low Stock'.tr,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final lowStockItems = controller.getLowStockItems();
            if (lowStockItems.isEmpty) {
              return Text('All items in stock'.tr);
            }
            return Column(
              children: lowStockItems.take(5).map((item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name, style: const TextStyle(fontSize: 14)),
                  trailing: Text(
                    '${item.quantity} ${'left'.tr}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    ),
  );
}
