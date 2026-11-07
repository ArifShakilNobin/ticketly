import '../utils/json_read.dart';

/// A message the notification service pushed out for the passenger.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.userId,
    this.channel,
    this.status,
    this.relatedId,
    this.sentAt,
  });

  final String id;
  final String title;
  final String body;
  final String? userId;
  final String? channel;
  final String? status;
  final String? relatedId;
  final DateTime? sentAt;

  factory AppNotification.fromJson(Map<String, dynamic>? json) {
    final data = asMap(json);
    return AppNotification(
      id: stringOr(data['id'], ''),
      title: stringOr(data['title'], ''),
      body: stringOr(data['body'], ''),
      userId: stringOrNull(data['userId']),
      channel: stringOrNull(data['channel']),
      status: stringOrNull(data['status']),
      relatedId: stringOrNull(data['relatedId']),
      sentAt: dateTimeOrNull(data['sentAt']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'channel': channel,
        'title': title,
        'body': body,
        'status': status,
        'relatedId': relatedId,
        if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
      };

  /// Whether the backend already marked this notification as read.
  bool get isRead => (status ?? '').toUpperCase() == 'READ';
}
