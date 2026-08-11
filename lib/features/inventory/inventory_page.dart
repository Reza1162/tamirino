import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';
import 'package:printing/printing.dart';
import 'barcode_label_generator.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('انبار قطعات')),
      body: StreamBuilder<List<Part>>(
        stream: DbProvider.repository.watchParts(),
        builder: (context, snapshot) {
          final parts = snapshot.data ?? [];
          if (parts.isEmpty) {
            return Center(
              child: Text('هنوز قطعه‌ای ثبت نشده', style: TextStyle(color: Colors.grey.shade500)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: parts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final part = parts[i];
              final low = part.quantity <= part.lowStockThreshold;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: low ? AppTheme.danger.withOpacity(0.12) : AppTheme.primaryLight,
                    child: Icon(Icons.memory_outlined, color: low ? AppTheme.danger : AppTheme.primary),
                  ),
                  title: Text(part.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('موجودی: ${part.quantity} — قیمت فروش: ${part.sellPrice} تومان'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (low)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Chip(label: Text('موجودی کم'), backgroundColor: Color(0xFFFDEAEA)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.qr_code, color: AppTheme.primary),
                        tooltip: 'چاپ برچسب بارکد',
                        onPressed: () async {
                          final bytes = await BarcodeLabelGenerator.generate(part);
                          await Printing.sharePdf(bytes: bytes, filename: 'barcode_${part.id}.pdf');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPartSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('قطعه جدید'),
      ),
    );
  }

  void _showAddPartSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final buyCtrl = TextEditingController();
    final sellCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('قطعه جدید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام قطعه')),
            const SizedBox(height: 12),
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'تعداد موجودی')),
            const SizedBox(height: 12),
            TextField(controller: buyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت خرید (تومان)')),
            const SizedBox(height: 12),
            TextField(controller: sellCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت فروش (تومان)')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await DbProvider.repository.addPart(
                    name: nameCtrl.text.trim(),
                    quantity: int.tryParse(qtyCtrl.text.trim()) ?? 0,
                    purchasePrice: int.tryParse(buyCtrl.text.trim()) ?? 0,
                    sellPrice: int.tryParse(sellCtrl.text.trim()) ?? 0,
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('ذخیره'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
