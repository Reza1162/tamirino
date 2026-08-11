import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';
import 'order_detail_page.dart';

class OrdersKanbanPage extends StatelessWidget {
  const OrdersKanbanPage({super.key});

  static const _columns = [
    {'key': 'registered', 'label': 'ثبت‌شده', 'color': Colors.blue},
    {'key': 'in_progress', 'label': 'در حال تعمیر', 'color': AppTheme.warning},
    {'key': 'ready', 'label': 'آماده تحویل', 'color': AppTheme.primary},
    {'key': 'delivered', 'label': 'تحویل‌شده', 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RepairOrder>>(
      stream: DbProvider.repository.watchRepairOrders(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _columns.map((col) {
              final colOrders = orders.where((o) => o.status == col['key']).toList();
              return Container(
                width: 250,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: col['color'] as Color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(col['label'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Text('(${colOrders.length})', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    DragTarget<int>(
                      onAcceptWithDetails: (details) async {
                        final orderId = details.data;
                        final db = DbProvider.database;
                        await (db.update(db.repairOrders)..where((t) => t.id.equals(orderId)))
                            .write(RepairOrdersCompanion(status: Value(col['key'] as String)));
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          constraints: const BoxConstraints(minHeight: 400),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: candidateData.isNotEmpty
                                ? AppTheme.primaryLight
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: colOrders.map((o) {
                              return Draggable<int>(
                                data: o.id,
                                feedback: Material(
                                  child: _OrderCard(order: o, dragging: true),
                                ),
                                childWhenDragging: Opacity(opacity: 0.3, child: _OrderCard(order: o)),
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => OrderDetailPage(order: o)),
                                  ),
                                  child: _OrderCard(order: o),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final RepairOrder order;
  final bool dragging;
  const _OrderCard({required this.order, this.dragging = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dragging ? 230 : null,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: dragging ? [const BoxShadow(color: Colors.black26, blurRadius: 8)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.issueDescription, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Text('#${order.id}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
