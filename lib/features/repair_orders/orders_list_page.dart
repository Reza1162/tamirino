import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';
import 'add_repair_order_page.dart';
import 'order_detail_page.dart';

class OrdersListPage extends StatefulWidget {
  const OrdersListPage({super.key});

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage> {
  String _filter = 'all';

  final _statusTabs = const [
    {'key': 'all', 'label': 'همه'},
    {'key': 'registered', 'label': 'ثبت‌شده'},
    {'key': 'in_progress', 'label': 'در حال تعمیر'},
    {'key': 'ready', 'label': 'آماده تحویل'},
    {'key': 'delivered', 'label': 'تحویل‌شده'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سفارش‌های تعمیر')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final tab = _statusTabs[i];
                final selected = _filter == tab['key'];
                return ChoiceChip(
                  label: Text(tab['label']!),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = tab['key']!),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<RepairOrder>>(
              stream: DbProvider.repository.watchRepairOrders(),
              builder: (context, snapshot) {
                var orders = (snapshot.data ?? []).reversed.toList();
                if (_filter != 'all') {
                  orders = orders.where((o) => o.status == _filter).toList();
                }
                if (orders.isEmpty) {
                  return Center(
                    child: Text('سفارشی یافت نشد', style: TextStyle(color: Colors.grey.shade500)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final o = orders[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(o.status).withOpacity(0.12),
                          child: Icon(Icons.build_outlined, color: _statusColor(o.status)),
                        ),
                        title: Text(o.issueDescription, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(_statusLabel(o.status)),
                        trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => OrderDetailPage(order: o)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddRepairOrderPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('سفارش جدید'),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'registered':
        return Colors.blue;
      case 'in_progress':
        return AppTheme.warning;
      case 'ready':
        return AppTheme.primary;
      case 'delivered':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'registered':
        return 'ثبت‌شده';
      case 'in_progress':
        return 'در حال تعمیر';
      case 'ready':
        return 'آماده تحویل';
      case 'delivered':
        return 'تحویل داده‌شده';
      default:
        return status;
    }
  }
}
