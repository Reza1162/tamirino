import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/share/eitaa_share.dart';
import '../../data/local/db_provider.dart';

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دعوت از دوستان')),
      body: FutureBuilder<String>(
        future: DbProvider.repository.getOrCreateReferralCode(),
        builder: (context, snapshot) {
          final code = snapshot.data ?? '...';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: AppTheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'هر تعمیرکاری که با کد شما ثبت‌نام کند،\nهر دو ۷ روز اشتراک حرفه‌ای رایگان می‌گیرید',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('کد دعوت شما', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const Icon(Icons.copy_outlined, color: AppTheme.primary),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.telegram_outlined),
                  label: const Text('اشتراک‌گذاری در ایتا'),
                  onPressed: () => EitaaShare.shareText(
                    'من از اپ تعمیرینو برای مدیریت تعمیرگاهم استفاده می‌کنم! با کد من ثبت‌نام کن تا هر دومون ۷ روز اشتراک حرفه‌ای رایگان بگیریم: $code',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('اشتراک‌گذاری با روش‌های دیگر'),
                  onPressed: () => Share.share(
                    'من از اپ تعمیرینو برای مدیریت تعمیرگاهم استفاده می‌کنم! با کد من ثبت‌نام کن تا هر دومون ۷ روز اشتراک حرفه‌ای رایگان بگیریم: $code',
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FutureBuilder<int>(
                future: DbProvider.repository.referralRewardDays(),
                builder: (context, snap) {
                  final days = snap.data ?? 0;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.groups_outlined, color: AppTheme.primary),
                      title: const Text('پاداش دریافتی'),
                      subtitle: Text('$days روز اشتراک حرفه‌ای از دعوت‌های موفق'),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
