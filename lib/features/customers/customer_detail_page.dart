import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/jalali_utils.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';
import '../devices/device_detail_page.dart';
import '../repair_orders/add_repair_order_page.dart';

class CustomerDetailPage extends StatelessWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: StreamBuilder<List<RepairOrder>>(
        stream: DbProvider.repository.watchRepairOrders(),
        builder: (context, snapshot) {
          final orders = (snapshot.data ?? [])
              .where((o) => o.customerId == customer.id)
              .toList()
              .reversed
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(customer.phone),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('عضویت: ${JalaliUtils.formatDate(customer.createdAt)}'),
                        ],
                      ),
                      if (customer.address != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(customer.address!)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('دستگاه‌های ثبت‌شده',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              StreamBuilder<List<Device>>(
                stream: DbProvider.repository.watchDevicesForCustomer(customer.id),
                builder: (context, snap) {
                  final devices = snap.data ?? [];
                  if (devices.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('دستگاهی ثبت نشده', style: TextStyle(color: Colors.grey.shade600)),
                    );
                  }
                  return Column(
                    children: devices.map((d) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.devices_other_outlined, color: AppTheme.primary),
                        title: Text(d.deviceType),
                        subtitle: d.brand != null ? Text(d.brand!) : null,
                        trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DeviceDetailPage(device: d)),
                        ),
                      ),
                    )).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('سابقه سفارش‌ها',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('هنوز سفارشی برای این مشتری ثبت نشده',
                      style: TextStyle(color: Colors.grey.shade600)),
                )
              else
                ...orders.map((o) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.build_outlined, color: AppTheme.primary),
                        title: Text(o.issueDescription),
                        subtitle: Text('وضعیت: ${_statusLabel(o.status)}'),
                      ),
                    )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddRepairOrderPage(preselectedCustomer: customer),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('سفارش جدید'),
      ),
    );
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
