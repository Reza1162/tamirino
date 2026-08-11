import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/db_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: FutureBuilder(
        future: DbProvider.repository.getBusinessSettings(),
        builder: (context, snapshot) {
          final business = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.primaryLight,
                        child: Icon(Icons.store_outlined, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business?.businessName ?? 'کسب‌وکار من',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            if (business != null)
                              Text(business.jobType, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _SettingsTile(icon: Icons.info_outline, title: 'درباره تعمیرینو'),
              const _SettingsTile(icon: Icons.support_agent_outlined, title: 'پشتیبانی'),
              const _SettingsTile(icon: Icons.share_outlined, title: 'دعوت از دوستان'),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SettingsTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
