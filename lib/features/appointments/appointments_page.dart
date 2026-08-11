import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/jalali_utils.dart';
import '../../data/local/database.dart';
import '../../data/local/db_provider.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نوبت‌دهی')),
      body: StreamBuilder<List<Appointment>>(
        stream: DbProvider.repository.watchAppointments(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];
          final dayEvents = all.where((a) => _sameDay(a.appointmentTime, _selectedDay)).toList();

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: TableCalendar<Appointment>(
                  locale: 'fa',
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => _sameDay(day, _selectedDay),
                  eventLoader: (day) => all.where((a) => _sameDay(a.appointmentTime, day)).toList(),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
                    todayTextStyle: TextStyle(color: AppTheme.primary),
                    markerDecoration: BoxDecoration(color: AppTheme.warning, shape: BoxShape.circle),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              Expanded(
                child: dayEvents.isEmpty
                    ? Center(
                        child: Text('نوبتی برای این روز ثبت نشده',
                            style: TextStyle(color: Colors.grey.shade500)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: dayEvents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final a = dayEvents[i];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.event_outlined, color: AppTheme.primary),
                              title: Text(a.title),
                              subtitle: Text(JalaliUtils.formatDateTime(a.appointmentTime)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                                onPressed: () => DbProvider.repository.deleteAppointment(a.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('نوبت جدید'),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    DateTime picked = _selectedDay;
    TimeOfDay pickedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نوبت جدید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان نوبت (مثلاً: نام مشتری)')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text('ساعت: ${pickedTime.format(context)}'),
                onPressed: () async {
                  final time = await showTimePicker(context: context, initialTime: pickedTime);
                  if (time != null) setSheetState(() => pickedTime = time);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final dateTime = DateTime(
                      picked.year, picked.month, picked.day,
                      pickedTime.hour, pickedTime.minute,
                    );
                    await DbProvider.repository.addAppointment(
                      title: titleCtrl.text.trim(),
                      appointmentTime: dateTime,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('ذخیره نوبت'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
