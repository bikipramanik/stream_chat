class ChatMessageModel {
  final String id;
  final String senderId;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? imageAttachment;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.imageAttachment,
  });

  String get formattedTime {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
