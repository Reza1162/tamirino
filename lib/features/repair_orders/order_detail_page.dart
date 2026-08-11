import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';
import '../invoice/invoice_generator.dart';

class OrderDetailPage extends StatefulWidget {
  final RepairOrder order;
  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late String _status;
  final _statusFlow = const ['registered', 'in_progress', 'ready', 'delivered'];
  final _paymentController = TextEditingController();

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

  Future<void> _addPayment() async {
    final amount = int.tryParse(_paymentController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('مبلغ معتبر وارد کنید')));
      return;
    }
    await DbProvider.repository.addPayment(
      repairOrderId: widget.order.id,
      amount: amount,
    );
    _paymentController.clear();
    setState(() {});
  }

  Future<void> _shareInvoice(int totalPaid) async {
    final db = DbProvider.database;
    final customer = await (db.select(db.customers)
          ..where((t) => t.id.equals(widget.order.customerId)))
        .getSingle();
    final business = await DbProvider.repository.getBusinessSettings();

    final bytes = await InvoiceGenerator.generate(
      order: widget.order,
      customer: customer,
      business: business,
      totalPaid: totalPaid,
    );

    await Printing.sharePdf(bytes: bytes, filename: 'invoice_${widget.order.id}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('سفارش #${widget.order.id}')),
      body: FutureBuilder<int>(
        future: DbProvider.repository.totalPaidForOrder(widget.order.id),
        builder: (context, snapshot) {
          final totalPaid = snapshot.data ?? 0;
          final cost = widget.order.finalCost ?? widget.order.estimatedCost ?? 0;
          final remaining = cost - totalPaid - widget.order.discount;

          return ListView(
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 24),
              const Text('مالی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _financeRow('هزینه کل', '$cost تومان'),
                      _financeRow('پرداخت‌شده', '$totalPaid تومان'),
                      const Divider(),
                      _financeRow(
                        'باقی‌مانده',
                        '$remaining تومان',
                        bold: true,
                        color: remaining > 0 ? AppTheme.danger : AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _paymentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'مبلغ پرداخت (تومان)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: _addPayment, child: const Text('ثبت')),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _shareInvoice(totalPaid),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('ساخت و اشتراک‌گذاری فاکتور'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _financeRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color)),
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
