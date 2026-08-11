import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/db_provider.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _loading = false;

  Future<void> _activate(Duration duration, String label) async {
    setState(() => _loading = true);
    await DbProvider.repository.activatePro(duration: duration);
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('اشتراک $label با موفقیت فعال شد')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ارتقا به حرفه‌ای')),
      body: FutureBuilder<bool>(
        future: DbProvider.repository.isPro(),
        builder: (context, snapshot) {
          final isPro = snapshot.data ?? false;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (isPro)
                Card(
                  color: AppTheme.primaryLight,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: AppTheme.primary),
                        SizedBox(width: 10),
                        Text('اشتراک حرفه‌ای شما فعال است', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('نسخه رایگان', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 6),
                        const Text('تا ۳۰ مشتری و ۳۰ سفارش فعال', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text('امکانات نسخه حرفه‌ای', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const _FeatureRow(text: 'مشتری و سفارش نامحدود'),
              const _FeatureRow(text: 'فاکتور با لوگوی برند شما'),
              const _FeatureRow(text: 'گزارش کامل سود و انبار'),
              const _FeatureRow(text: 'پشتیبان‌گیری کامل'),
              const SizedBox(height: 28),
              if (!isPro) ...[
                _PlanCard(
                  title: 'اشتراک ماهانه',
                  price: '۹۹,۰۰۰ تومان',
                  onTap: _loading ? null : () => _activate(const Duration(days: 30), 'ماهانه'),
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  title: 'اشتراک سالانه',
                  price: '۷۹۰,۰۰۰ تومان',
                  badge: 'صرفه‌جویی ۳۳٪',
                  highlighted: true,
                  onTap: _loading ? null : () => _activate(const Duration(days: 365), 'سالانه'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String? badge;
  final bool highlighted;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    this.badge,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: highlighted ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: highlighted ? AppTheme.primary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: highlighted ? Colors.white : Colors.black87,
                )),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Text(badge!, style: TextStyle(
                    fontSize: 12,
                    color: highlighted ? Colors.white70 : AppTheme.primary,
                  )),
                ],
              ],
            ),
            Text(price, style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: highlighted ? Colors.white : AppTheme.primary,
            )),
          ],
        ),
      ),
    );
  }
}
