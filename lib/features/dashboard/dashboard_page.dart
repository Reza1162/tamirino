import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';
import '../reminders/reminders_page.dart';
import '../customers/customers_page.dart';
import '../repair_orders/add_repair_order_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعمیرینو'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RemindersPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomersPage()),
            ),
          ),
        ],
      ),
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
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(label: 'تعمیرات جدید', value: '$newCount', color: Colors.blue),
                  _StatCard(label: 'در حال تعمیر', value: '$inProgress', color: AppTheme.warning),
                  _StatCard(label: 'آماده تحویل', value: '$ready', color: AppTheme.primary),
                  _StatCard(label: 'تحویل داده‌شده', value: '$delivered', color: Colors.grey),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<int>>(
                future: Future.wait([
                  DbProvider.repository.todayIncome(),
                  DbProvider.repository.totalDebt(),
                ]),
                builder: (context, snap) {
                  final income = snap.data?[0] ?? 0;
                  final debt = snap.data?[1] ?? 0;
                  return Row(
                    children: [
                      Expanded(
                        child: _MiniStat(label: 'درآمد امروز', value: '$income تومان', color: AppTheme.primary, icon: Icons.payments_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStat(label: 'طلب از مشتریان', value: '$debt تومان', color: AppTheme.danger, icon: Icons.account_balance_wallet_outlined),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('سفارش‌های اخیر',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      const Text('هنوز سفارشی ثبت نشده',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                ...orders.reversed.map((order) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryLight,
                          child: Icon(Icons.build_outlined, color: AppTheme.primary),
                        ),
                        title: Text(order.issueDescription,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('سفارش #${order.id}'),
                      ),
                    )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddRepairOrderPage()),
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(right: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
