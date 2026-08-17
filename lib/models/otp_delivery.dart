/// Where an OTP was delivered, so the UI can point the user to the right inbox.
///
/// The server sends the code by SMS first and falls back to email (site SMTP)
/// if the SMS send fails.
class OtpDelivery {
  /// Delivery channel: `'sms'` or `'email'`.
  final String channel;

  /// Masked destination for email (e.g. `n***@host.com`); null for SMS.
  final String? sentTo;

  const OtpDelivery({this.channel = 'sms', this.sentTo});

  bool get isEmail => channel == 'email';

  factory OtpDelivery.fromMessage(Map<String, dynamic>? msg) => OtpDelivery(
        channel: msg?['channel']?.toString() ?? 'sms',
        sentTo: (msg?['sent_to'] as Object?)?.toString(),
      );
}
