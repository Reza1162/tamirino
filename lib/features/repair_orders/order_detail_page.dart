import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';

class OrderDetailPage extends StatefulWidget {
  final RepairOrder order;
  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late String _status;

  final _statusFlow = const ['registered', 'in_progress', 'ready', 'delivered'];

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    final db = DbProvider.database;
    await (db.update(db.repairOrders)..where((t) => t.id.equals(widget.order.id)))
        .write(RepairOrdersCompanion(status: Value(newStatus)));
    setState(() => _status = newStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('سفارش #${widget.order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('شرح خرابی', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(widget.order.issueDescription, style: const TextStyle(fontSize: 16)),
                  if (widget.order.estimatedCost != null) ...[
                    const SizedBox(height: 14),
                    const Text('برآورد هزینه', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${widget.order.estimatedCost} تومان', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('تغییر وضعیت', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusFlow.map((s) {
              final selected = _status == s;
              return ChoiceChip(
                label: Text(_statusLabel(s)),
                selected: selected,
                onSelected: (_) => _updateStatus(s),
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
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
