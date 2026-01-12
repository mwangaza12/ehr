// lib/models/chat_message.dart
class ChatMessage {
  final int? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? modelUsed;
  final double? confidence;
  final String? attachmentPath;
  final String? attachmentType;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.modelUsed,
    this.confidence,
    this.attachmentPath,
    this.attachmentType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': text,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'model_used': modelUsed,
      'confidence': confidence,
      'attachment_path': attachmentPath,
      'attachment_type': attachmentType,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      text: map['message'],
      isUser: map['is_user'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
      modelUsed: map['model_used'],
      confidence: map['confidence'],
      attachmentPath: map['attachment_path'],
      attachmentType: map['attachment_type'],
    );
  }
}