import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../App Clolor/app_color.dart';
import 'firebase_service.dart';

class ChatScreen extends StatefulWidget {
  final String sender;
  final String receiver;
  final String name;
  final String email;

  ChatScreen({
    required this.sender,
    required this.receiver,
    required this.name,
    required this.email,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseService service = FirebaseService();
  final TextEditingController msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (msgController.text.trim().isEmpty) return;

    service.sendMessage(widget.sender, widget.receiver, msgController.text.trim());
    msgController.clear();

    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onMessageLongPress(String messageId, bool isMyMessage) {
    if (!isMyMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You can only delete your own messages"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _showDeleteMessageDialog(messageId);
  }

  void _showDeleteMessageDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Message"),
        content: Text("Are you sure you want to delete this message? "),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await service.deleteMessage(widget.sender, widget.receiver, messageId);
              },
              child: Text("Delete")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.lightGreen,
              child: Text(
                widget.name[0].toUpperCase(),
                style: TextStyle(color: AppColors.forest, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(widget.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: AppColors.textLight),
            onSelected: (value) {
              if (value == 'clear') service.clearChat(widget.sender, widget.receiver);
              if (value == 'delete') service.deleteChat(widget.sender, widget.receiver);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'clear', child: Text("Clear Chat")),
              PopupMenuItem(value: 'delete', child: Text("Delete Chat")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: service.getMessages(widget.sender, widget.receiver),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index];
                    bool isMe = msg["sender"] == widget.sender;
                    Timestamp? timestamp = msg["time"];
                    String timeStr = timestamp != null ? DateFormat.jm().format(timestamp.toDate()) : "";

                    return _buildMessageBubble(msg.id, msg["message"], isMe, timeStr);
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String messageId, String message, bool isMe, String time) {
    return Padding(
      padding: EdgeInsets.only(left: isMe ? 50 : 0, right: isMe ? 0 : 50, top: 4, bottom: 4),
      child: GestureDetector(
        onLongPress: () => _onMessageLongPress(messageId, isMe),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.messageSender : AppColors.messageReceiver,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text(time, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}