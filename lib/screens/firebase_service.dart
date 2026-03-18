import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> saveUser(String name, String email, String password, String phone) async {
    await _firestore.collection("users").doc(email).set({
      "name": name,
      "email": email,  // Add email field to the document
      "phone": phone,  // Add phone field
      "password": password,
      "createdAt": DateTime.now(),
      "lastSeen": DateTime.now(),
    });
  }

  Future<DocumentSnapshot> getUser(String email) async {
    return await _firestore.collection("users").doc(email).get();
  }

  Stream<QuerySnapshot> getUsers() {
    return _firestore.collection("users").orderBy("name").snapshots();
  }

  Future<void> sendMessage(String sender, String receiver, String message) async {
    if (message.trim().isEmpty) return;
    String chatId = _generateChatId(sender, receiver);
    await _firestore.collection("chats").doc(chatId).collection("messages").add({
      "sender": sender,
      "receiver": receiver,
      "message": message.trim(),
      "time": FieldValue.serverTimestamp(),
    });
    await _firestore.collection("chats").doc(chatId).set({
      "lastMessage": message.trim(),
      "lastMessageTime": FieldValue.serverTimestamp(),
      "participants": [sender, receiver],
    }, SetOptions(merge: true));
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
    String chatId = _generateChatId(sender, receiver);
    await _firestore.collection("chats").doc(chatId).collection("messages").doc(messageId).delete();
  }

  Future<void> clearChat(String user1, String user2) async {
    String chatId = _generateChatId(user1, user2);
    QuerySnapshot messages = await _firestore.collection("chats").doc(chatId).collection("messages").get();
    WriteBatch batch = _firestore.batch();
    for (var doc in messages.docs) batch.delete(doc.reference);
    batch.update(_firestore.collection("chats").doc(chatId), {
      "lastMessage": "Chat cleared",
      "lastMessageTime": FieldValue.serverTimestamp(),
      "isCleared": true,
    });
    await batch.commit();
  }

  Future<void> deleteChat(String user1, String user2) async {
    String chatId = _generateChatId(user1, user2);
    QuerySnapshot messages = await _firestore.collection("chats").doc(chatId).collection("messages").get();
    WriteBatch batch = _firestore.batch();
    for (var doc in messages.docs) batch.delete(doc.reference);
    batch.delete(_firestore.collection("chats").doc(chatId));
    await batch.commit();
  }

  Stream<QuerySnapshot> getUserChats(String userEmail) {
    return _firestore.collection("chats").where("participants", arrayContains: userEmail).snapshots();
  }
}