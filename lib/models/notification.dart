class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // message, reminder, alert, system
  final DateTime date;
  bool isRead;
  final String? icon;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.date,
    this.isRead = false,
    this.icon,
  });

  static List<AppNotification> mockNotifications() => [
    AppNotification(
      id: '1',
      title: 'New Message',
      body: 'We have reviewed your latest readings.\nKeep up the good work!',
      type: 'message',
      date: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: '2',
      title: 'Appointment Reminder',
      body: 'You have an appointment with Nurse Ayaan\non Friday, May 24 at 9:00 AM.',
      type: 'reminder',
      date: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    AppNotification(
      id: '3',
      title: 'Medication Reminder',
      body: "It's time to take your evening medication.\nStay on track!",
      type: 'reminder',
      date: DateTime.now().subtract(const Duration(hours: 20)),
    ),
    AppNotification(
      id: '4',
      title: 'System Update',
      body: "We've made improvements to help you\nmonitor your health better.",
      type: 'system',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}
