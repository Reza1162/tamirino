import 'package:url_launcher/url_launcher.dart';

class EitaaShare {
  /// اشتراک‌گذاری متن مستقیم در ایتا (پیام یا کد دعوت)
  static Future<bool> shareText(String text) async {
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://eitaa.com/share/url?url=&text=$encoded');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
