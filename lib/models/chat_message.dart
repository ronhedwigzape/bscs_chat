import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  String? messageId;
  String userId;
  String text;
  DateTime timestamp;
  String? profileImageUrl;

  ChatMessage({
    this.messageId,
    required this.userId,
    required this.text,
    required this.timestamp,
    this.profileImageUrl,
  });

  // Convert a ChatMessage object to JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'userId': userId,
      'text': text,
      'timestamp': timestamp,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Create a ChatMessage object from a map
  static ChatMessage fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map['messageId'],
      userId: map['userId'],
      text: map['text'],
      timestamp: map['timestamp'].toDate(), // Assuming timestamp is a Timestamp type in Firestore
      profileImageUrl: map['profileImageUrl'],
    );
  }

  // Create a ChatMessage object from a Firestore DocumentSnapshot
  static ChatMessage fromSnapshot(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return ChatMessage.fromMap(snapshot);
  }
}
