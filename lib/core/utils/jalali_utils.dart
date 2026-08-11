import 'package:shamsi_date/shamsi_date.dart';

class JalaliUtils {
  /// نمایش تاریخ مثل: ۱۴۰۴/۰۵/۲۱
  static String formatDate(DateTime dateTime) {
    final j = Jalali.fromDateTime(dateTime);
    return '${_toPersianDigits(j.year)}/${_pad(j.month)}/${_pad(j.day)}';
  }

  /// نمایش تاریخ و ساعت مثل: ۱۴۰۴/۰۵/۲۱ - ۱۴:۳۰
  static String formatDateTime(DateTime dateTime) {
    final j = Jalali.fromDateTime(dateTime);
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '${formatDate(dateTime)} - ${_toPersianDigits(int.parse(hh))}:${_toPersianDigits(int.parse(mm), pad: 2)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _toPersianDigits(int number, {int pad = 0}) {
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var s = number.toString();
    if (pad > 0) s = s.padLeft(pad, '0');
    return s.split('').map((c) {
      final d = int.tryParse(c);
      return d == null ? c : fa[d];
    }).join();
  }
}
