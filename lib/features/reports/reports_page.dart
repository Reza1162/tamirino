import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/db_provider.dart';
import '../inventory/inventory_page.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('گزارش‌ها')),
      body: FutureBuilder<Map<String, int>>(
        future: DbProvider.repository.profitReport(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {'revenue': 0, 'partsCost': 0, 'profit': 0, 'ordersCount': 0};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppTheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('سود خالص', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('${data['profit']} تومان',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('از ${data['ordersCount']} سفارش تحویل‌شده', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _ReportCard(label: 'درآمد کل', value: '${data['revenue']} تومان', color: Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _ReportCard(label: 'هزینه قطعات', value: '${data['partsCost']} تومان', color: AppTheme.warning)),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary),
                  title: const Text('مدیریت انبار قطعات'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InventoryPage()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ReportCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
