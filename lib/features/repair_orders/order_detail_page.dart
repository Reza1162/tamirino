import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/jalali_utils.dart';
import 'signature_page.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';
import '../invoice/invoice_generator.dart';
import '../invoice/estimate_generator.dart';

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
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
    _noteController = TextEditingController(text: widget.order.notes ?? '');
  }

  Future<void> _updateStatus(String newStatus) async {
    final db = DbProvider.database;
    await (db.update(db.repairOrders)..where((t) => t.id.equals(widget.order.id)))
        .write(RepairOrdersCompanion(status: Value(newStatus)));
    setState(() => _status = newStatus);
  }

  Future<void> _addPhoto(String stage) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'order_photos'));
    if (!await photosDir.exists()) await photosDir.create(recursive: true);

    final fileName = 'order_${widget.order.id}_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final savedPath = p.join(photosDir.path, fileName);
    await File(picked.path).copy(savedPath);

    await DbProvider.repository.addOrderPhoto(
      repairOrderId: widget.order.id,
      filePath: savedPath,
      stage: stage,
    );
  }

  Widget _buildWarrantySection() {
    final hasWarranty = widget.order.warrantyDays != null;
    final underWarranty = hasWarranty ? _isUnderWarranty() : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: hasWarranty ? AppTheme.primary : Colors.grey),
                const SizedBox(width: 8),
                const Text('گارانتی تعمیر', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.order.signaturePath == null)
              OutlinedButton.icon(
                icon: const Icon(Icons.draw_outlined),
                label: const Text('دریافت امضای تحویل مشتری'),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SignaturePage(orderId: widget.order.id)),
                  );
                  setState(() {});
                },
              )
            else
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(widget.order.signaturePath!), width: 80, height: 40, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 10),
                  const Text('امضا ثبت شده', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            const SizedBox(height: 14),
            if (!hasWarranty)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'مدت گارانتی'),
                      items: const [
                        DropdownMenuItem(value: 7, child: Text('۷ روز')),
                        DropdownMenuItem(value: 15, child: Text('۱۵ روز')),
                        DropdownMenuItem(value: 30, child: Text('۳۰ روز')),
                        DropdownMenuItem(value: 90, child: Text('۳ ماه')),
                        DropdownMenuItem(value: 180, child: Text('۶ ماه')),
                      ],
                      onChanged: (v) async {
                        if (v == null) return;
                        await DbProvider.repository.setWarranty(widget.order.id, v);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Chip(
                    label: Text(underWarranty == true ? 'در گارانتی' : 'گارانتی تمام‌شده'),
                    backgroundColor: underWarranty == true
                        ? AppTheme.primaryLight
                        : Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: underWarranty == true ? AppTheme.primary : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (widget.order.deliveredAt != null && widget.order.warrantyDays != null)
                    Text(
                      'تا ${JalaliUtils.formatDate(widget.order.deliveredAt!.add(Duration(days: widget.order.warrantyDays!)))}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimateSection() {
    final status = widget.order.estimateStatus;
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = AppTheme.primary;
        label = 'تأیید شده توسط مشتری';
        break;
      case 'declined':
        color = AppTheme.danger;
        label = 'رد شده توسط مشتری';
        break;
      default:
        color = AppTheme.warning;
        label = 'در انتظار تأیید مشتری';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.request_quote_outlined, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text('پیش‌فاکتور', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Chip(
                  label: Text(label, style: const TextStyle(fontSize: 11)),
                  backgroundColor: color.withOpacity(0.12),
                  labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('ارسال پیش‌فاکتور'),
                    onPressed: () async {
                      final db = DbProvider.database;
                      final customer = await (db.select(db.customers)
                            ..where((t) => t.id.equals(widget.order.customerId)))
                          .getSingle();
                      final business = await DbProvider.repository.getBusinessSettings();
                      final bytes = await EstimateGenerator.generate(
                        order: widget.order, customer: customer, business: business,
                      );
                      await Printing.sharePdf(bytes: bytes, filename: 'estimate_${widget.order.id}.pdf');
                    },
                  ),
                ),
              ],
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await DbProvider.repository.setEstimateStatus(widget.order.id, 'approved');
                        setState(() {});
                      },
                      child: const Text('تأیید مشتری'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                      onPressed: () async {
                        await DbProvider.repository.setEstimateStatus(widget.order.id, 'declined');
                        setState(() {});
                      },
                      child: const Text('رد مشتری'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isUnderWarranty() {
    if (widget.order.deliveredAt == null || widget.order.warrantyDays == null) return false;
    final expiry = widget.order.deliveredAt!.add(Duration(days: widget.order.warrantyDays!));
    return DateTime.now().isBefore(expiry);
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
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFFFFF8E1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text('یادداشت داخلی (فقط شما می‌بینید)',
                              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'مثلاً: قطعه از فلان مغازه بگیر، مشتری حساسه...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (v) => DbProvider.repository.setInternalNote(widget.order.id, v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.order.estimatedCost != null) _buildEstimateSection(),
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
              if (widget.order.status == 'delivered') _buildWarrantySection(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('عکس‌های دستگاه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_a_photo_outlined, color: AppTheme.primary),
                        tooltip: 'عکس قبل از تعمیر',
                        onPressed: () => _addPhoto('before'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: AppTheme.primary),
                        tooltip: 'عکس بعد از تعمیر',
                        onPressed: () => _addPhoto('after'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<OrderPhoto>>(
                stream: DbProvider.repository.watchOrderPhotos(widget.order.id),
                builder: (context, snap) {
                  final photos = snap.data ?? [];
                  if (photos.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('عکسی ثبت نشده', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    );
                  }
                  return SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final photo = photos[i];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(photo.filePath),
                                width: 100, height: 100, fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4, left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: photo.stage == 'before' ? AppTheme.warning : AppTheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  photo.stage == 'before' ? 'قبل' : 'بعد',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
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
