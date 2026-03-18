import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate consistent chat ID (sorted to ensure same chat regardless of order)
  String _generateChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> saveUser(String name, String phone) async {
    try {
      await _firestore.collection("users").doc(phone).set({
        "name": name,
        "phone": phone,
        "createdAt": DateTime.now(),
        "lastSeen": DateTime.now(),
      });
    } catch (e) {
      print("Error saving user: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getUsers() {
    return _firestore
        .collection("users")
        .orderBy("name")
        .snapshots();
  }

  Future<void> sendMessage(
      String sender, String receiver, String message) async {

    if (message.trim().isEmpty) return;

    try {
      String chatId = _generateChatId(sender, receiver);

      await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .add({
        "sender": sender,
        "receiver": receiver,
        "message": message.trim(),
        "time": FieldValue.serverTimestamp(),
      });

      // Update last message for chat preview (optional)
      await _firestore.collection("chats").doc(chatId).set({
        "lastMessage": message.trim(),
        "lastMessageTime": FieldValue.serverTimestamp(),
        "participants": [sender, receiver],
      }, SetOptions(merge: true));

    } catch (e) {
      print("Error sending message: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getMessages(String sender, String receiver) {
    String chatId = _generateChatId(sender, receiver);
    return _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("time", descending: false)
        .snapshots();
  }



  Future<void> deleteMessage(String sender, String receiver, String messageId) async {
    try {
      String chatId = _generateChatId(sender, receiver);
      await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .doc(messageId)
          .delete();
    } catch (e) {
      print("Error deleting message: $e");
      rethrow;
    }
  }
  Future<DocumentSnapshot> getUser(String phone) async {
    return await _firestore.collection("users").doc(phone).get();
  }


  Future<void> clearChat(String user1, String user2) async {
    try {
      String chatId = _generateChatId(user1, user2);

      // Get all messages in this chat
      QuerySnapshot messages = await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .get();

      // Delete each message
      WriteBatch batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Update chat document to show it's cleared
      batch.update(
          _firestore.collection("chats").doc(chatId),
          {
            "lastMessage": "Chat cleared",
            "lastMessageTime": FieldValue.serverTimestamp(),
            "isCleared": true,
          }
      );

      await batch.commit();
      print("Chat cleared successfully");

    } catch (e) {
      print("Error clearing chat: $e");
      rethrow;
    }
  }

  /// Delete entire chat (including the chat document)
  Future<void> deleteChat(String user1, String user2) async {
    try {
      String chatId = _generateChatId(user1, user2);

      // First delete all messages
      QuerySnapshot messages = await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Then delete the chat document itself
      batch.delete(_firestore.collection("chats").doc(chatId));

      await batch.commit();
      print("Chat deleted successfully");

    } catch (e) {
      print("Error deleting chat: $e");
      rethrow;
    }
  }

  // Add this to firebase_service.dart
  Stream<QuerySnapshot> getUserChats(String userPhone) {
    return _firestore
        .collection("chats")
        .where("participants", arrayContains: userPhone)
    //.orderBy("lastMessageTime", descending: true)
        .snapshots();
  }
}