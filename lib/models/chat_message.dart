import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String text;
  final DateTime timestamp;
  final bool isEdited;
  final bool isDeleted;
  final String? profileImage;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.text,
    required this.timestamp,
    this.isEdited = false,
    this.isDeleted = false,
    this.profileImage,
  });

  // A factory constructor for creating a ChatMessage from a Firestore document.
  factory ChatMessage.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatMessage(
      id: doc.id,
      userId: data['userId'] as String,
      text: data['text'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isEdited: data.containsKey('isEdited') ? data['isEdited'] as bool : false,
      isDeleted: data.containsKey('isDeleted') ? data['isDeleted'] as bool : false,
      profileImage: data['profileImage'] as String?,
    );
  }
}
