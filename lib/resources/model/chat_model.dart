import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel{
  String? message;
  String? sender;
  DateTime? timeAt;

  ChatModel({
    this.message,
    this.sender,
    this.timeAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'message': message!,
      'sender': sender!,
      'timeAt': timeAt!.toIso8601String(),    // DateTime to String
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> data) {
    return ChatModel(
      message: data['message'],
      sender: data['sender'],
      timeAt: DateTime.parse(data['timeAt']),   // String ISO8601 to DateTime
    );
  }

  factory ChatModel.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map;
    return ChatModel(
      message: data['message'],
      sender: data['sender'],
      timeAt: DateTime.parse(data['timeAt']),   // String ISO8601 to DateTime
    );
  }

  void reset() {
    message = null;
    sender = null;
    timeAt = null;
  }
}
