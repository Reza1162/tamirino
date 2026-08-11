import 'package:flutter/material.dart';
import '../../data/local/db_provider.dart';
import '../subscription/subscription_page.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('نام مشتری را وارد کنید')));
      return;
    }
    if (!await DbProvider.repository.canAddCustomer()) {
      if (!mounted) return;
      _showLimitDialog();
      return;
    }
    setState(() => _saving = true);
    await DbProvider.repository.addCustomer(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('محدودیت نسخه رایگان'),
        content: const Text('نسخه رایگان تا ۳۰ مشتری اجازه ثبت می‌دهد. برای ادامه، به نسخه حرفه‌ای ارتقا دهید.'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مشتری جدید')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'نام و نام خانوادگی'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'شماره موبایل'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'آدرس (اختیاری)'),
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
                  : const Text('ذخیره مشتری'),
            ),
          ),
        ],
      ),
    );
  }
}
