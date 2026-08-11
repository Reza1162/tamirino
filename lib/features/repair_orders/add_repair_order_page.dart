import 'package:flutter/material.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';
import '../subscription/subscription_page.dart';

class AddRepairOrderPage extends StatefulWidget {
  final Customer? preselectedCustomer;
  const AddRepairOrderPage({super.key, this.preselectedCustomer});

  @override
  State<AddRepairOrderPage> createState() => _AddRepairOrderPageState();
}

class _AddRepairOrderPageState extends State<AddRepairOrderPage> {
  Customer? _selectedCustomer;
  final _deviceTypeController = TextEditingController();
  final _issueController = TextEditingController();
  final _costController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
  }

  Future<void> _save() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('یک مشتری انتخاب کنید')));
      return;
    }
    if (_issueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('شرح خرابی را وارد کنید')));
      return;
    }
    if (!await DbProvider.repository.canAddOrder()) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('محدودیت نسخه رایگان'),
          content: const Text('نسخه رایگان تا ۳۰ سفارش فعال اجازه ثبت می‌دهد. برای ادامه، به نسخه حرفه‌ای ارتقا دهید.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بعداً')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionPage()));
              },
              child: const Text('ارتقا'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = DbProvider.repository;

    int? deviceId;
    if (_deviceTypeController.text.trim().isNotEmpty) {
      deviceId = await repo.addDevice(
        customerId: _selectedCustomer!.id,
        deviceType: _deviceTypeController.text.trim(),
      );
    }

    await repo.addRepairOrder(
      customerId: _selectedCustomer!.id,
      deviceId: deviceId,
      issueDescription: _issueController.text.trim(),
      estimatedCost: int.tryParse(_costController.text.trim()),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سفارش تعمیر جدید')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.preselectedCustomer == null)
            StreamBuilder<List<Customer>>(
              stream: DbProvider.repository.watchCustomers(),
              builder: (context, snapshot) {
                final customers = snapshot.data ?? [];
                return DropdownButtonFormField<Customer>(
                  value: _selectedCustomer,
                  decoration: const InputDecoration(labelText: 'مشتری'),
                  items: customers
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (c) => setState(() => _selectedCustomer = c),
                );
              },
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 10),
                    Text(widget.preselectedCustomer!.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _deviceTypeController,
            decoration: const InputDecoration(
              labelText: 'نوع دستگاه',
              hintText: 'مثلاً: گوشی سامسونگ A54',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _issueController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'شرح خرابی'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _costController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'برآورد هزینه (تومان)'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('ثبت سفارش'),
            ),
          ),
        ],
      ),
    );
  }
}
