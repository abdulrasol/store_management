import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/services/version_check_service.dart';
import 'package:store_management/ui/expense_add.dart';
import 'package:store_management/ui/expenses_page.dart';
import 'package:store_management/ui/purchases_page.dart';
import 'package:store_management/ui/reports_page.dart';
import 'package:store_management/ui/salaries_page.dart';
import 'package:store_management/ui/store_settings.dart';
import 'package:store_management/ui/suppliers_page.dart';
import 'package:store_management/ui/about_page.dart';
import 'package:store_management/ui/urgent_orders_page.dart';
import 'package:store_management/models/urgent_order.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final databaseController = Get.find<DatabaseController>();
  final settingsController = Get.find<SettingsController>();

  final RxString _summaryPeriod = 'Month'.obs;
  final RxString _chartPeriod = 'Week'.obs;
  final RxString _chartType = 'expenses'.obs;

  final Rx<double> _purchasesTotal = 0.0.obs;
  final Rx<double> _salariesTotal = 0.0.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionCheckService().checkVersion(context);
      _checkOverdueUrgentOrders();
      _loadAsyncTotals();
    });
    ever(_summaryPeriod, (_) => _loadAsyncTotals());
  }

  void _loadAsyncTotals() async {
    final range = _getDateRange(_summaryPeriod.value);
    final pTotal = await databaseController.getPurchasesTotal(range.$1, range.$2);
    final sTotal = await databaseController.getSalariesTotal(range.$1, range.$2);
    _purchasesTotal.value = pTotal;
    _salariesTotal.value = sTotal;
  }

  (DateTime, DateTime) _getDateRange(String period) {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = now.add(const Duration(days: 1));
    if (period == 'Week') {
      start = now.subtract(const Duration(days: 6));
      start = DateTime(start.year, start.month, start.day);
    } else if (period == 'Month') {
      start = now.subtract(const Duration(days: 29));
      start = DateTime(start.year, start.month, start.day);
    } else {
      start = DateTime(now.year, 1, 1);
    }
    return (start, end);
  }

  Future<void> _checkOverdueUrgentOrders() async {
    try {
      final orders = await databaseController.getUrgentOrders();
      final now = DateTime.now();
      final overdueOrders = orders.where((o) {
        if (o.isCompleted) return false;
        final diff = now.difference(o.date).inDays;
        return diff > 3;
      }).toList();

      if (overdueOrders.isEmpty) return;

      final String title;
      final String message;
      if (overdueOrders.length == 1) {
        title = 'تنبيه - طلب متأخر'.tr;
        message = 'الطلب "${overdueOrders.first.name}" متأخر منذ ${now.difference(overdueOrders.first.date).inDays} يوم'.tr;
      } else {
        title = 'تنبيه - ${overdueOrders.length} طلبات متأخرة'.tr;
        message = overdueOrders
            .map((o) => '• ${o.name} (منذ ${now.difference(o.date).inDays} يوم)')
            .join('\n');
      }

      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('إغلاق'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.to(() => const UrgentOrdersPage());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('عرض الطلبات'.tr),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async {
          databaseController.loading();
          _loadAsyncTotals();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodToggle(),
              const SizedBox(height: 16),
              _buildFinancialOverview(context),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildExpensesChart(context),
              const SizedBox(height: 24),
              _buildRecentExpenses(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settingsController.appName.value ?? 'Store Management'.tr,
                style: TextStyle(fontFamily: 'Cairo', color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
              ),
              Text(
                DateTime.now().toString().split(' ')[0],
                style: Theme.of(context).textTheme.bodySmall,
              )
            ],
          )),
      actions: const [SizedBox(width: 8)],
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(
        () => Row(
          children: [
            _toggleButton('Week', _summaryPeriod.value == 'Week', () => _summaryPeriod.value = 'Week'),
            _toggleButton('Month', _summaryPeriod.value == 'Month', () => _summaryPeriod.value = 'Month'),
            _toggleButton('Year', _summaryPeriod.value == 'Year', () => _summaryPeriod.value = 'Year'),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width / 2 - 24;

    return Obx(() {
      final range = _getDateRange(_summaryPeriod.value);
      final expenses = databaseController.getExpenses(range.$1, range.$2);
      final purchases = _purchasesTotal.value;
      final salaries = _salariesTotal.value;
      final totalSpending = expenses + purchases + salaries;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainCard(
            context,
            title: 'Total Spending'.tr,
            value: settingsController.currencyFormatter(totalSpending),
            icon: Icons.account_balance_wallet,
            gradient: [Colors.blue.shade700, Colors.blue.shade900],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard(
                onTap: () => Get.to(() => const PurchasesPage()),
                title: 'Purchases'.tr,
                icon: Icons.shopping_cart,
                color: Colors.indigo,
                value: Text(
                  settingsController.currencyFormatter(purchases),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                width: cardWidth,
              ),
              _statCard(
                onTap: () => Get.to(() => ExpensesPage()),
                title: 'Expenses'.tr,
                icon: Icons.receipt_long,
                color: Colors.orange,
                value: Text(
                  settingsController.currencyFormatter(expenses),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                width: cardWidth,
              ),
              _statCard(
                onTap: () => Get.to(() => const SalariesPage()),
                title: 'Salaries'.tr,
                icon: Icons.payments,
                color: Colors.purple,
                value: Text(
                  settingsController.currencyFormatter(salaries),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                width: cardWidth,
              ),
              _statCard(
                onTap: () => Get.to(() => SupplierPage()),
                title: 'Debts'.tr,
                icon: Icons.money_off,
                color: Colors.red,
                value: Text(
                  settingsController.currencyFormatter(databaseController.customerDebt()),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                width: cardWidth,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBreakdownBar(context, purchases, expenses, salaries, totalSpending),
        ],
      );
    });
  }

  Widget _buildBreakdownBar(BuildContext context, double purchases, double expenses, double salaries, double total) {
    if (total == 0) return const SizedBox.shrink();
    final pPct = purchases / total;
    final ePct = expenses / total;
    final sPct = salaries / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(flex: (pPct * 1000).round().clamp(1, 1000), child: Container(color: Colors.indigo)),
                Expanded(flex: (ePct * 1000).round().clamp(1, 1000), child: Container(color: Colors.orange)),
                Expanded(flex: (sPct * 1000).round().clamp(1, 1000), child: Container(color: Colors.purple)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _legendDot(Colors.indigo, 'Purchases'.tr, '${(pPct * 100).toStringAsFixed(0)}%'),
            _legendDot(Colors.orange, 'Expenses'.tr, '${(ePct * 100).toStringAsFixed(0)}%'),
            _legendDot(Colors.purple, 'Salaries'.tr, '${(sPct * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label, String pct) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label $pct', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildMainCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: gradient.first.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget value,
    required double width,
    void Function()? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                if (onTap != null) Icon(Icons.arrow_forward_ios, size: 12, color: color.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 4),
            value,
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions'.tr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionButton(
                icon: Icons.shopping_cart_outlined,
                label: 'Purchases'.tr,
                color: Colors.indigo,
                onTap: () => Get.to(() => const PurchasesPage()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionButton(
                icon: Icons.add_circle_outline,
                label: 'New Expense'.tr,
                color: Colors.orange,
                onTap: () => Get.to(() => const ExpenseAdd()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionButton(
                icon: Icons.payments_outlined,
                label: 'Salaries'.tr,
                color: Colors.purple,
                onTap: () => Get.to(() => const SalariesPage()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionButton(
                icon: Icons.local_shipping_outlined,
                label: 'Suppliers'.tr,
                color: Colors.teal,
                onTap: () => Get.to(() => SupplierPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesChart(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          _toggleButton('Expenses'.tr, _chartType.value == 'expenses', () => _chartType.value = 'expenses', compact: true),
                          _toggleButton('Purchases'.tr, _chartType.value == 'purchases', () => _chartType.value = 'purchases', compact: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 32,
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        _toggleButton('Week', _chartPeriod.value == 'Week', () => _chartPeriod.value = 'Week', compact: true),
                        _toggleButton('Month', _chartPeriod.value == 'Month', () => _chartPeriod.value = 'Month', compact: true),
                        _toggleButton('Year', _chartPeriod.value == 'Year', () => _chartPeriod.value = 'Year', compact: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AspectRatio(
                aspectRatio: 1.7,
                child: Builder(builder: (context) {
                  Map<DateTime, double> dataMap;

                  if (_chartType.value == 'expenses') {
                    switch (_chartPeriod.value) {
                      case 'Month':
                        dataMap = databaseController.getMonthlyExpenses();
                        break;
                      case 'Year':
                        dataMap = databaseController.getYearlyExpenses();
                        break;
                      case 'Week':
                      default:
                        dataMap = databaseController.getWeeklyExpenses();
                        break;
                    }
                  } else {
                    switch (_chartPeriod.value) {
                      case 'Month':
                        dataMap = databaseController.getMonthlySales();
                        break;
                      case 'Year':
                        dataMap = databaseController.getYearlySales();
                        break;
                      case 'Week':
                      default:
                        dataMap = databaseController.getWeeklySales();
                        break;
                    }
                  }

                  if (dataMap.isEmpty || dataMap.values.every((v) => v == 0)) {
                    return Center(child: Text('No data available'.tr));
                  }

                  final keys = dataMap.keys.toList()..sort();
                  final barColor = _chartType.value == 'expenses' ? Colors.orange : Colors.indigo;

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: dataMap.values.isEmpty ? 100 : (dataMap.values.reduce((a, b) => a > b ? a : b) * 1.2),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            DateTime date = keys[group.x.toInt()];
                            String label = '';
                            if (_chartPeriod.value == 'Week') {
                              label = _getWeekdayName(date.weekday);
                            } else if (_chartPeriod.value == 'Month') {
                              label = '${date.day}/${date.month}';
                            } else {
                              label = '${_getMonthName(date.month)} ${date.year}';
                            }
                            return BarTooltipItem(
                              '$label\n',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              children: <TextSpan>[
                                TextSpan(
                                  text: settingsController.currencyFormatter(rod.toY),
                                  style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index < 0 || index >= keys.length) return const SizedBox.shrink();
                              DateTime date = keys[index];
                              String text = '';
                              if (_chartPeriod.value == 'Week') {
                                text = _getWeekdayName(date.weekday).substring(0, 3);
                              } else if (_chartPeriod.value == 'Month') {
                                if (date.day % 5 == 0 || date.day == 1) {
                                  text = '${date.day}';
                                } else {
                                  return const SizedBox.shrink();
                                }
                              } else {
                                text = _getMonthName(date.month).substring(0, 3);
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(keys.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: dataMap[keys[index]] ?? 0,
                              color: barColor,
                              width: _chartPeriod.value == 'Month' ? 6 : 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            )
                          ],
                        );
                      }),
                    ),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRecentExpenses(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Expenses'.tr, style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: () => Get.to(() => ExpensesPage()), child: Text('See All'.tr)),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          final recentExpenses = databaseController.expenses.toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          final display = recentExpenses.take(5).toList();

          if (display.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('No expenses yet'.tr, style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: display.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final expense = display[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  child: const Icon(Icons.receipt_long, color: Colors.orange, size: 20),
                ),
                title: Text(
                  expense.description.isNotEmpty ? expense.description : 'Expense'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(expense.getDate(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: Text(
                  settingsController.currencyFormatter(expense.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        await Get.to(() => const ExpenseAdd());
        databaseController.loading();
        _loadAsyncTotals();
      },
      backgroundColor: Colors.orange,
      icon: const Icon(Icons.add),
      label: Text('New Expense'.tr),
    );
  }

  Widget _toggleButton(String text, bool isActive, VoidCallback onTap, {bool compact = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
        ),
        child: Text(
          text.tr,
          style: TextStyle(fontSize: compact ? 11 : 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black : Colors.grey),
        ),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (weekday < 1 || weekday > 7) return '';
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: settingsController.logo.value != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: Image.memory(
                            base64Decode(settingsController.logo.value!),
                            fit: BoxFit.cover,
                            width: 70,
                            height: 70,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: Image.asset(
                            'assets/png/logo.png',
                            fit: BoxFit.cover,
                            width: 70,
                            height: 70,
                          ),
                        ),
                ),
                const SizedBox(height: 15),
                Text(
                  settingsController.appName.value ?? 'Store Management',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your store easily and efficiently'.tr,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _drawerItem('Home'.tr, Icons.home_outlined, () => Get.back()),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4), child: Divider()),
                _drawerItem('Purchases'.tr, Icons.shopping_cart_outlined, () => Get.to(() => const PurchasesPage())),
                _drawerItem('Expenses'.tr, Icons.receipt_long_outlined, () => Get.to(() => ExpensesPage())),
                _drawerItem('Salaries'.tr, Icons.payments_outlined, () => Get.to(() => const SalariesPage())),
                _drawerItem('Suppliers'.tr, Icons.local_shipping_outlined, () => Get.to(() => SupplierPage())),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4), child: Divider()),
                _drawerItem('الطلبات المستعجلة'.tr, Icons.priority_high_rounded, () => Get.to(() => const UrgentOrdersPage())),
                _drawerItem('التقارير'.tr, Icons.article_outlined, () => Get.to(() => const ReportsPage())),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4), child: Divider()),
                _drawerItem('App Settings'.tr, Icons.settings_outlined, () => Get.to(() => StoreSettings())),
                _drawerItem('About'.tr, Icons.info_outline, () => Get.to(() => const AboutPage())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700], size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      horizontalTitleGap: 12,
    );
  }
}
