import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/ui/invoice_view.dart';

import '../controllers/database_controller.dart';
import '../controllers/settings_controller.dart';

SettingsController settingsController = Get.find();
DatabaseController databaseController = Get.find();

class ProfitsPage extends StatelessWidget {
  const ProfitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profits'.tr),
        elevation: 0,
      ),
      body: Obx(() {
        // Sort explicitly by date descending for display
        final profits = databaseController.profits.toList()..sort((a, b) => b.date.compareTo(a.date));

        return Column(
          children: [
            // Total Net Profit Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Net Profit'.tr,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              )),
                      const SizedBox(height: 8),
                      Text(
                        settingsController.currencyFormatter(databaseController.profits.fold(0.0, (sum, p) => sum + p.profit())),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                  Icon(Icons.trending_up, size: 48, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: profits.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final profit = profits[index];
                  final invoice = profit.invoice.target;
                  if (invoice == null) return const SizedBox.shrink();

                  final amount = profit.profit();
                  final isPositive = amount >= 0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () => Get.to(() => InvoiceView(invoice: invoice)),
                    leading: CircleAvatar(
                      backgroundColor: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      child: Icon(
                        isPositive ? Icons.arrow_outward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      settingsController.currencyFormatter(amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green : Colors.red,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${'Invoice Number'.tr}: ${invoice.invoiceNumber()}'),
                        Text(invoice.invoiceDate(), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
