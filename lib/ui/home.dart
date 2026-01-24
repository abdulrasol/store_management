import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/services/version_check_service.dart';
import 'package:store_management/ui/customer_view.dart';
import 'package:store_management/ui/customers_page.dart';
import 'package:store_management/ui/dashboard_page.dart';
import 'package:store_management/ui/expenses_page.dart';
import 'package:store_management/ui/forms/invoice_form.dart';
import 'package:store_management/ui/invoice_view.dart';
import 'package:store_management/ui/invoices_page.dart';
import 'package:store_management/ui/items_page.dart';
import 'package:store_management/ui/profits_page.dart';
import 'package:store_management/ui/search_delegate.dart';
import 'package:store_management/ui/store_settings.dart';
import 'package:store_management/ui/suppliers_page.dart';
import 'package:store_management/ui/about_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final databaseController = Get.find<DatabaseController>();
  final settingsController = Get.find<SettingsController>();

  // Local state for chart toggle
  final RxString _summaryPeriod = 'Month'.obs; // Week, Month, Year - Default Month
  final RxString _chartPeriod = 'Week'.obs; // Week, Month, Year

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionCheckService().checkVersion(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async {
          // await databaseController.loadData();
          databaseController.loading(); // Refresh data manually just in case
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(context),
              const SizedBox(height: 24),
              // _buildProfitOverview(context), // Removed per request
              _buildSalesChart(context),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTopSellingItems(context)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildLowStockAlerts(context)),
                ],
              ),

              const SizedBox(height: 24),
              _buildRecentInvoices(context),
              const SizedBox(height: 24),
              _buildDebtorsList(context),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: _buildSpeedDial(),
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
                settingsController.appName.value ?? 'Sales Management App'.tr,
                style: TextStyle(fontFamily: 'Cairo', color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
              ),
              Text(
                DateTime.now().toString().split(' ')[0],
                style: Theme.of(context).textTheme.bodySmall,
              )
            ],
          )),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            showSearch(context: context, delegate: SearchDelegateHelper());
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- Dashboard Widgets ---

  Widget _buildSummaryCards(BuildContext context) {
    // 2 cards per row for better readability on mobile
    double cardWidth = MediaQuery.of(context).size.width / 2 - 24;

    return Column(
      children: [
        // Analytics Period Toggles
        Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Obx(
            () => Row(
              children: [
                _chartToggleButton(context, 'Week', _summaryPeriod.value == 'Week', () => _summaryPeriod.value = 'Week'),
                _chartToggleButton(context, 'Month', _summaryPeriod.value == 'Month', () => _summaryPeriod.value = 'Month'),
                _chartToggleButton(context, 'Year', _summaryPeriod.value == 'Year', () => _summaryPeriod.value = 'Year'),
              ],
            ),
          ),
        ),

        Obx(() {
          DateTime now = DateTime.now();
          DateTime start;
          DateTime end = now.add(const Duration(days: 1)); // Include today fully

          if (_summaryPeriod.value == 'Week') {
            // Last 7 days
            start = now.subtract(const Duration(days: 6));
            start = DateTime(start.year, start.month, start.day);
          } else if (_summaryPeriod.value == 'Month') {
            // Last 30 days
            start = now.subtract(const Duration(days: 29));
            start = DateTime(start.year, start.month, start.day);
          } else {
            // This Year (Jan 1)
            start = DateTime(now.year, 1, 1);
          }

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statCard(
                onTap: () => Get.to(() => InvoicesPage()),
                title: 'Total Sales'.tr,
                icon: Icons.attach_money,
                color: Colors.teal,
                value: Text(
                  settingsController.currencyFormatter(
                    databaseController.getSales(start, end),
                  ),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                width: cardWidth,
              ),
              _statCard(
                onTap: () => Get.to(() => ProfitsPage()),
                title: 'Net Profit'.tr, // Renamed from Net Revenue for clarity in context
                icon: Icons.bar_chart,
                color: Colors.deepPurple,
                value: Text(
                  settingsController.currencyFormatter(databaseController.getNetRevenue(start, end)),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                width: cardWidth,
              ),
              _statCard(
                onTap: () => Get.to(() => ProfitsPage()),
                title: 'Profits'.tr, // New Card replacing Items Count
                icon: Icons.trending_up,
                color: Colors.green,
                value: Text(
                  settingsController.currencyFormatter(databaseController.getProfit(start, end)),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                width: cardWidth,
              ),
              _statCard(
                title: 'Debts'.tr,
                icon: Icons.money_off_csred,
                color: Colors.redAccent,
                value: Text(
                  settingsController.currencyFormatter(databaseController.customerDebt()),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                width: cardWidth,
              ),
            ],
          );
        }),
      ],
    );
  }

  // Helper for toggle buttons (reused from chart section, moved up or kept here)
  /* Widget _chartToggleButton... is already defined below at line 364. 
     We can reuse it if scope allows, or move it up. 
     Since it's an instance method, it can be called from here. */

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
              children: [Icon(icon, color: color, size: 28), if (onTap != null) Icon(Icons.arrow_forward_ios, size: 12, color: color.withValues(alpha: 0.5))],
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            value,
          ],
        ),
      ),
    );
  }

  // --- Dashboard Widgets ---

  Widget _buildSalesChart(BuildContext context) {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_chartPeriod.value}ly Sales'.tr.replaceAll('Week ly', 'Weekly').replaceAll('Month ly', 'Monthly').replaceAll('Year ly', 'Yearly'),
                    // Fallback to simple keys if translation complex, but let's try to map:
                    // 'Week' -> 'Weekly Sales', 'Month' -> 'Monthly Sales', 'Year' -> 'Yearly Sales'
                    // actually better to just translate the full string based on value
                  ),
                  // Toggle Button
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _chartToggleButton(context, 'Week', _chartPeriod.value == 'Week', () => _chartPeriod.value = 'Week'),
                        _chartToggleButton(context, 'Month', _chartPeriod.value == 'Month', () => _chartPeriod.value = 'Month'),
                        _chartToggleButton(context, 'Year', _chartPeriod.value == 'Year', () => _chartPeriod.value = 'Year'),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              AspectRatio(
                aspectRatio: 1.7,
                child: Builder(builder: (context) {
                  // Prepare Data
                  Map<DateTime, double> dataMap;
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

                  if (dataMap.isEmpty || dataMap.values.every((v) => v == 0)) {
                    return Center(child: Text('No data available'.tr));
                  }

                  final keys = dataMap.keys.toList()..sort();

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
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: rod.toY.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                // Show every 5th day to avoid clutter or logic ok for 30 bars?
                                // 30 bars is tight. Let's show only if index % 5 == 0
                                if (date.day % 5 == 0 || date.day == 1) {
                                  text = '${date.day}';
                                } else {
                                  return const SizedBox.shrink();
                                }
                              } else {
                                // Year
                                text = _getMonthName(date.month).substring(0, 3);
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
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
                              color: _chartPeriod.value == 'Year' ? Colors.orange : (_chartPeriod.value == 'Month' ? Colors.indigo : Colors.teal),
                              width: _chartPeriod.value == 'Month' ? 6 : 12, // thinner bars for month
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

  Widget _chartToggleButton(BuildContext context, String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
        ),
        child: Text(text.tr, // Translate button text
            style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black : Colors.grey)),
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

  Widget _buildTopSellingItems(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Items'.tr,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final topItems = databaseController.getTopSellingItems();
              if (topItems.isEmpty) {
                return Text('No sales yet'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey));
              }
              return Column(
                children: topItems.take(3).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.teal),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item['name'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                        Text('${item['count']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
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

  Widget _buildLowStockAlerts(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Low Stock'.tr,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final lowStockItems = databaseController.getLowStockItems();
              if (lowStockItems.isEmpty) {
                return Text('OK'.tr, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
              }
              return Column(
                children: lowStockItems.take(3).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, size: 8, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                        Text('${item.quantity}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
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

  Widget _buildDebtorsList(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Debts'.tr,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Get.to(() => CustomersPage()),
                  child: Text('See All'.tr),
                )
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final debtors = databaseController.getDebtors();
              if (debtors.isEmpty) {
                return Text('OK'.tr, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold));
              }
              // Sort by debt (largest debt first, so most negative balance)
              debtors.sort((a, b) => a.balance().compareTo(b.balance())); // -100 vs -50. -100 is smaller.

              return Column(
                children: debtors.take(5).map((customer) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () => Get.to(() => CustomerView(customer: customer)),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(child: Text(customer.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
                          Text(settingsController.currencyFormatter(customer.balance()),
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
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

  // --- End Dashboard Widgets ---

  Widget _buildRecentInvoices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions'.tr, style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: () => Get.to(() => InvoicesPage()), child: Text('See All'.tr))
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: databaseController.inovices.length > 5 ? 5 : databaseController.inovices.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              var invoice = databaseController.inovices[index];
              return ListTile(
                onTap: () => Get.to(() => InvoiceView(invoice: invoice)),
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.withValues(alpha: 0.1),
                  child: const Icon(Icons.receipt, color: Colors.teal),
                ),
                title: Text(invoice.customer.target!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(invoice.invoiceDate(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: Text(settingsController.currencyFormatter(invoice.pricetoPay()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDial() {
    return FloatingActionButton.extended(
      onPressed: () {
        Get.to(() => InvoiceForm());
      },
      backgroundColor: Colors.teal,
      icon: const Icon(Icons.add),
      label: Text('New Sale'.tr),
    );
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
                  backgroundColor: Colors.teal.withValues(alpha: 0.1),
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
                      : const Icon(Icons.storefront, size: 35, color: Colors.teal),
                ),
                const SizedBox(height: 15),
                Text(
                  settingsController.appName.value ?? 'Sales Management App'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your store easily and efficiently'.tr,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _drawerItem('Home'.tr, Icons.store_outlined, () => Get.back()),
                _drawerItem('items'.tr, Icons.shopping_bag_outlined, () => Get.to(() => ItemsPage())),
                _drawerItem('customers'.tr, Icons.groups_outlined, () => Get.to(() => CustomersPage())),
                _drawerItem('Suppliers'.tr, Icons.local_shipping_outlined, () => Get.to(() => SupplierPage())),
                _drawerItem('Expenses'.tr, Icons.receipt_long_outlined, () => Get.to(() => ExpensesPage())),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(),
                ),
                _drawerItem('Full Analytics'.tr, Icons.insights_outlined, () => Get.to(() => const DashboardPage())),
                _drawerItem('App Settings'.tr, Icons.settings_outlined, () => Get.to(() => StoreSettings())),
                _drawerItem('About'.tr, Icons.info_outline, () => Get.to(() => const AboutPage())),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back(); // Close drawer
                      Get.defaultDialog(
                          title: "Fix Database Checks".tr,
                          middleText: "This will check all invoices and ensure debits are correctly recorded. Use this if Customer Balances look incorrect.".tr,
                          textConfirm: "Run Fix".tr,
                          confirmTextColor: Colors.white,
                          onConfirm: () {
                            databaseController.fixDatabaseTransactions();
                            Get.back();
                          },
                          textCancel: "Cancel".tr,
                          cancelTextColor: Colors.grey);
                    },
                    icon: Icon(Icons.build, size: 16),
                    label: Text("Fix Data Errors".tr),
                  ),
                ),
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
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      horizontalTitleGap: 12, // Reduce gap for a tighter look
    );
  }
}
