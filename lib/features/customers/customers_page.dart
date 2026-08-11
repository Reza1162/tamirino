import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';
import 'add_customer_page.dart';
import 'customer_detail_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مشتریان')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'جستجوی نام یا شماره تماس...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: DbProvider.repository.watchCustomers(),
              builder: (context, snapshot) {
                var customers = snapshot.data ?? [];
                if (_query.isNotEmpty) {
                  customers = customers
                      .where((c) =>
                          c.name.contains(_query) || c.phone.contains(_query))
                      .toList();
                }
                if (customers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _query.isEmpty ? 'هنوز مشتری‌ای ثبت نشده' : 'نتیجه‌ای یافت نشد',
                            style: const TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = customers[customers.length - 1 - index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryLight,
                          child: Text(
                            c.name.isNotEmpty ? c.name[0] : '؟',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(c.phone),
                        trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CustomerDetailPage(customer: c)),
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
          MaterialPageRoute(builder: (_) => const AddCustomerPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('مشتری جدید'),
      ),
    );
  }
}
