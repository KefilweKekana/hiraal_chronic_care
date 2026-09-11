/// Parse remaining wait from EMR OTP rate-limit errors.
///
/// Server message shape: "Please wait 87 seconds before requesting another code".
int? parseOtpRetryAfterSeconds(String? message) {
  if (message == null || message.trim().isEmpty) return null;
  final seconds = RegExp(r'(\d+)\s+seconds?', caseSensitive: false).firstMatch(message);
  if (seconds != null) {
    return int.parse(seconds.group(1)!).clamp(1, 3600);
  }
  final minutes = RegExp(r'(\d+)\s+minutes?', caseSensitive: false).firstMatch(message);
  if (minutes != null) {
    return (int.parse(minutes.group(1)!) * 60).clamp(1, 3600);
  }
  return null;
}

/// `87` → `1:27`, `45` → `0:45`.
String formatOtpCountdown(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final m = safe ~/ 60;
  final s = safe % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
