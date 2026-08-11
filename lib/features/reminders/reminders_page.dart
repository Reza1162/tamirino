import 'package:flutter/material.dart';
import '../../core/utils/jalali_utils.dart';
import '../../core/theme/app_theme.dart';
import '../../core/notifications/notification_service.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('یادآوری‌ها')),
      body: StreamBuilder<List<Reminder>>(
        stream: DbProvider.repository.watchReminders(),
        builder: (context, snapshot) {
          final reminders = snapshot.data ?? [];
          if (reminders.isEmpty) {
            return Center(
              child: Text('یادآوری‌ای ثبت نشده', style: TextStyle(color: Colors.grey.shade500)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = reminders[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: r.isDone ? Colors.grey.shade200 : AppTheme.primaryLight,
                    child: Icon(
                      r.isDone ? Icons.check : Icons.notifications_active_outlined,
                      color: r.isDone ? Colors.grey : AppTheme.primary,
                    ),
                  ),
                  title: Text(
                    r.title,
                    style: TextStyle(
                      decoration: r.isDone ? TextDecoration.lineThrough : null,
                      color: r.isDone ? Colors.grey : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(JalaliUtils.formatDateTime(r.remindAt)),
                  trailing: r.isDone
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                          onPressed: () => DbProvider.repository.deleteReminder(r.id),
                        )
                      : IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: AppTheme.primary),
                          onPressed: () => DbProvider.repository.markReminderDone(r.id),
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('یادآوری جدید'),
      ),
    );
  }

  void _showAddReminderSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    DateTime? picked;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('یادآوری جدید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان یادآوری')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(picked == null ? 'انتخاب تاریخ و ساعت' : JalaliUtils.formatDateTime(picked!)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null) return;
                  if (!context.mounted) return;
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time == null) return;
                  setState(() {
                    picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty || picked == null) return;
                    final id = await DbProvider.repository.addReminder(
                      title: titleCtrl.text.trim(),
                      remindAt: picked!,
                    );
                    await NotificationService.scheduleReminder(
                      id: id,
                      title: 'تعمیرینو',
                      body: titleCtrl.text.trim(),
                      dateTime: picked!,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('ذخیره'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
