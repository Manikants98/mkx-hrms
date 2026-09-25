class NotificationRecord {
  final int id;
  final String title;
  final String message;
  final String? type;
  final String? senderName;
  final bool isRead;
  final String createdAt;

  NotificationRecord({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.senderName,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationRecord.fromJson(Map<String, dynamic> json) {
    return NotificationRecord(
      id: json['id'] as int,
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      type: json['type'],
      senderName: json['sender_name'],
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }

  NotificationRecord copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    String? senderName,
    bool? isRead,
    String? createdAt,
  }) {
    return NotificationRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      senderName: senderName ?? this.senderName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
