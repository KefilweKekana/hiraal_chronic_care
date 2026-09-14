import 'package:intl/intl.dart';

/// Format dates without crashing when the UI locale (e.g. Somali) has no
/// intl date symbols. Falls back to English patterns.
String safeDateFormat(DateTime date, String pattern, [String? locale]) {
  final preferred = (locale == null || locale.isEmpty || locale.startsWith('so'))
      ? 'en'
      : locale;
  try {
    return DateFormat(pattern, preferred).format(date);
  } catch (_) {
    try {
      return DateFormat(pattern, 'en').format(date);
    } catch (_) {
      return DateFormat(pattern).format(date);
    }
  }
}
