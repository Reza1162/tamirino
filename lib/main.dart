import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_page.dart';
import 'app/main_shell.dart';
import 'data/local/db_provider.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const TamirinoApp());
}

class TamirinoApp extends StatelessWidget {
  const TamirinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تعمیرینو',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      theme: AppTheme.light,
      home: FutureBuilder(
        future: DbProvider.repository.watchCustomers().first,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final hasCustomers = (snapshot.data as List).isNotEmpty;
          return hasCustomers ? const MainShell() : const OnboardingPage();
        },
      ),
    );
  }
}
