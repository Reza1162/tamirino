import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعمیرینو')),
      body: ListView(
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
            children: const [
              _StatCard(label: 'تعمیرات جدید', value: '۰', color: Colors.blue),
              _StatCard(label: 'در حال تعمیر', value: '۰', color: Colors.orange),
              _StatCard(label: 'آماده تحویل', value: '۰', color: Colors.green),
              _StatCard(label: 'تحویل داده‌شده', value: '۰', color: Colors.grey),
            ],
          ),
          const SizedBox(height: 24),
          _InfoRow(
            icon: Icons.payments_outlined,
            title: 'درآمد امروز',
            value: '۰ تومان',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'طلب از مشتریان',
            value: '۰ تومان',
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          const Text('کارهای امروز',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const _EmptyTasks(),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('این بخش در مرحله بعد فعال می‌شود')),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'هنوز کاری برای امروز ثبت نشده',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
