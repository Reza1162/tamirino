import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
                      _LogoPicker(logoPath: business?.logoPath),
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
              _NavTile(
                icon: Icons.share_outlined,
                title: 'دعوت از دوستان',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReferralPage()),
                ),
              ),
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

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}


class _LogoPicker extends StatefulWidget {
  final String? logoPath;
  const _LogoPicker({required this.logoPath});

  @override
  State<_LogoPicker> createState() => _LogoPickerState();
}

class _LogoPickerState extends State<_LogoPicker> {
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.logoPath;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(picked.path);
    final savedPath = p.join(dir.path, 'business_logo\$ext');
    await File(picked.path).copy(savedPath);

    await DbProvider.repository.updateLogo(savedPath);
    setState(() => _currentPath = savedPath);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickLogo,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primaryLight,
            backgroundImage: _currentPath != null ? FileImage(File(_currentPath!)) : null,
            child: _currentPath == null
                ? const Icon(Icons.store_outlined, color: AppTheme.primary)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
