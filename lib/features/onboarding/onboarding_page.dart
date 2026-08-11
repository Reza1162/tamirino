import 'package:flutter/material.dart';
import '../dashboard/dashboard_page.dart';
import '../../data/local/db_provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentStep = 0;

  String? _selectedJob;
  final _businessNameController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _deviceTypeController = TextEditingController();
  final _issueController = TextEditingController();

  final List<Map<String, String>> _jobOptions = const [
    {'emoji': '📱', 'label': 'تعمیر موبایل'},
    {'emoji': '💻', 'label': 'تعمیر کامپیوتر'},
    {'emoji': '🏠', 'label': 'لوازم خانگی'},
    {'emoji': '❄️', 'label': 'کولر و پکیج'},
    {'emoji': '🔧', 'label': 'خدمات فنی'},
    {'emoji': '🚗', 'label': 'خودرو'},
    {'emoji': '✳️', 'label': 'سایر'},
  ];

  void _nextStep() async {
    if (_currentStep == 0 && _selectedJob == null) {
      _showError('لطفاً شغل خودت رو انتخاب کن');
      return;
    }
    if (_currentStep == 1 && _businessNameController.text.trim().isEmpty) {
      _showError('لطفاً نام کسب‌وکارت رو وارد کن');
      return;
    }
    if (_currentStep == 2 && _customerNameController.text.trim().isEmpty) {
      _showError('لطفاً نام مشتری رو وارد کن');
      return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final repo = DbProvider.repository;

      await repo.saveBusinessSettings(
        businessName: _businessNameController.text.trim(),
        jobType: _selectedJob!,
      );

      final customerId = await repo.addCustomer(
        name: _customerNameController.text.trim(),
        phone: _customerPhoneController.text.trim(),
      );

      if (_deviceTypeController.text.trim().isNotEmpty) {
        final deviceId = await repo.addDevice(
          customerId: customerId,
          deviceType: _deviceTypeController.text.trim(),
        );

        await repo.addRepairOrder(
          customerId: customerId,
          deviceId: deviceId,
          issueDescription: _issueController.text.trim().isEmpty
              ? 'بدون توضیح'
              : _issueController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _deviceTypeController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildJobStep(),
                  _buildBusinessNameStep(),
                  _buildFirstCustomerStep(),
                  _buildFirstOrderStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  child: Text(_currentStep < 3 ? 'ادامه' : 'شروع کن'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(4, (i) {
          final active = i <= _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildJobStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('شغلت چیست؟',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: _jobOptions.length,
              itemBuilder: (context, index) {
                final job = _jobOptions[index];
                final selected = _selectedJob == job['label'];
                return InkWell(
                  onTap: () => setState(() => _selectedJob = job['label']),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(job['emoji']!, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(job['label']!, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessNameStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نام کسب‌وکارت چیست؟',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('این اسم روی فاکتورهات نشون داده می‌شه',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              hintText: 'مثلاً: موبایل سرویس رضا',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstCustomerStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اولین مشتری رو اضافه کن',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _customerNameController,
            decoration: const InputDecoration(
              labelText: 'نام مشتری',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'شماره موبایل',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstOrderStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اولین سفارش تعمیر رو ثبت کن',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _deviceTypeController,
            decoration: const InputDecoration(
              labelText: 'نوع دستگاه',
              hintText: 'مثلاً: گوشی سامسونگ A54',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _issueController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'شرح خرابی',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
