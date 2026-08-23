import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? imageAttachment;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.imageAttachment,
  });

  factory ChatMessageModel.fromMap(
    Map<String, dynamic> map,
    String docId,
    String currentUid,
  ) {
    DateTime parsedTimestamp;
    if (map['timestamp'] is Timestamp) {
      parsedTimestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(map['timestamp']);
    } else {
      parsedTimestamp = DateTime.now();
    }

    final sender = map['senderId'] ?? '';

    return ChatMessageModel(
      id: docId,
      senderId: sender,
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      isMe: sender == currentUid,
      timestamp: parsedTimestamp,
      imageAttachment: map['imageAttachment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      if (imageAttachment != null) 'imageAttachment': imageAttachment,
    };
  }

  String get formattedTime {
    final hour = timestamp.hour > 12
        ? timestamp.hour - 12
        : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

