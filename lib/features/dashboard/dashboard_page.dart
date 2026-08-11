import 'package:flutter/material.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعمیرینو')),
      body: StreamBuilder<List<RepairOrder>>(
        stream: DbProvider.repository.watchRepairOrders(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          final newCount = orders.where((o) => o.status == 'registered').length;
          final inProgress = orders.where((o) => o.status == 'in_progress').length;
          final ready = orders.where((o) => o.status == 'ready').length;
          final delivered = orders.where((o) => o.status == 'delivered').length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('امروز',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(label: 'تعمیرات جدید', value: '$newCount', color: Colors.blue),
                  _StatCard(label: 'در حال تعمیر', value: '$inProgress', color: Colors.orange),
                  _StatCard(label: 'آماده تحویل', value: '$ready', color: Colors.green),
                  _StatCard(label: 'تحویل داده‌شده', value: '$delivered', color: Colors.grey),
                ],
              ),
              const SizedBox(height: 24),
              const Text('سفارش‌های اخیر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('هنوز سفارشی ثبت نشده',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ...orders.reversed.map((order) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.build_outlined),
                          const SizedBox(width: 12),
                          Expanded(child: Text(order.issueDescription)),
                          Text('#${order.id}'),
                        ],
                      ),
                    )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فرم ثبت سفارش در مرحله بعد اضافه می‌شود')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('سفارش تعمیر'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}
