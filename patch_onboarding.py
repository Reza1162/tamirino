import re

path = "lib/features/onboarding/onboarding_page.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace(
    "import '../dashboard/dashboard_page.dart';",
    "import '../dashboard/dashboard_page.dart';\nimport '../../data/local/db_provider.dart';"
)

old_next_step = '''  void _nextStep() {
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
  }'''

new_next_step = '''  void _nextStep() async {
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
  }'''

if old_next_step not in content:
    raise SystemExit("الگوی قدیمی پیدا نشد - فایل دستی چک شود")

content = content.replace(old_next_step, new_next_step)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("OK")
