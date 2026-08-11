import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';

class DeviceDetailPage extends StatelessWidget {
  final Device device;
  const DeviceDetailPage({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device.deviceType)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (device.brand != null) _infoRow('برند', device.brand!),
                  if (device.model != null) _infoRow('مدل', device.model!),
                  if (device.serialNumber != null) _infoRow('سریال / IMEI', device.serialNumber!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('تاریخچه تعمیرات این دستگاه',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          StreamBuilder<List<RepairOrder>>(
            stream: DbProvider.repository.watchOrdersForDevice(device.id),
            builder: (context, snapshot) {
              final orders = (snapshot.data ?? []).reversed.toList();
              if (orders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('سابقه‌ای برای این دستگاه ثبت نشده',
                      style: TextStyle(color: Colors.grey.shade600)),
                );
              }
              return Column(
                children: orders.map((o) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.build_outlined, color: AppTheme.primary),
                    title: Text(o.issueDescription),
                    subtitle: Text('وضعیت: ${_statusLabel(o.status)}'),
                    trailing: o.warrantyDays != null && o.deliveredAt != null
                        ? Icon(
                            DateTime.now().isBefore(o.deliveredAt!.add(Duration(days: o.warrantyDays!)))
                                ? Icons.shield
                                : Icons.shield_outlined,
                            color: DateTime.now().isBefore(o.deliveredAt!.add(Duration(days: o.warrantyDays!)))
                                ? AppTheme.primary
                                : Colors.grey,
                            size: 20,
                          )
                        : null,
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
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
