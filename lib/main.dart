import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_page.dart';

void main() {
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
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: AppTheme.light,
      home: const OnboardingPage(),
    );
  }
}
