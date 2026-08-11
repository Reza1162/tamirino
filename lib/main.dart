import 'package:flutter/material.dart';

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
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
        fontFamily: 'Vazir',
      ),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.build_circle, size: 72, color: Color(0xFF2E7D32)),
              SizedBox(height: 16),
              Text(
                'تعمیرینو',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'تعمیرگاهت رو با گوشی مدیریت کن',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
