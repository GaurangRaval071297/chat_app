import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../App Clolor/app_color.dart';
import 'chat_screen.dart';
import 'firebase_service.dart';
import 'login_screen.dart';

class ChatDashboard extends StatefulWidget {
  final String phone;
  ChatDashboard({required this.phone});

  @override
  _ChatDashboardState createState() => _ChatDashboardState();
}

class _ChatDashboardState extends State<ChatDashboard> {
  final FirebaseService service = FirebaseService();

  // Logout function
  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Logout",
            style: TextStyle(color: AppColors.forest),
          ),
          content: Text("Are you sure you want to logout?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text("Logging out..."),
                      ],
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );

                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show all users dialog for new chat
  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.background,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.chat_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "New Chat",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Users list
                  Expanded(
                    child: StreamBuilder(
                      stream: service.getUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Error loading users"),
                          );
                        }

                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          );
                        }

                        var users = snapshot.data!.docs;

                        // Filter out current user
                        var otherUsers = users.where((user) {
                          String currentPhone = widget.phone.toString().trim().replaceAll(RegExp(r'\s+'), '');
                          String userPhone = user["phone"].toString().trim().replaceAll(RegExp(r'\s+'), '');

                          // Remove any non-digit characters
                          currentPhone = currentPhone.replaceAll(RegExp(r'[^0-9]'), '');
                          userPhone = userPhone.replaceAll(RegExp(r'[^0-9]'), '');

                          return userPhone != currentPhone;
                        }).toList();

                        if (otherUsers.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: AppColors.primary.withOpacity(0.5),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No other users found",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Invite friends to join!",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: otherUsers.length,
                          itemBuilder: (context, index) {
                            var user = otherUsers[index];

                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.lightGreen,
                                  child: Text(
                                    user["name"][0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user["name"],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    user["phone"],
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                trailing: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context); // Close bottom sheet
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        sender: widget.phone,
                                        receiver: user["phone"],
                                        name: user["name"],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(
          "Chats",
          style: TextStyle(color: AppColors.textLight),
        ),
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        actions: [
          // Logout button
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.textLight),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),

      body: _buildChatsTab(),

      // Floating Action Button for new chat
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: AppColors.primary,
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
        tooltip: 'New Chat',
      ),
    );
  }

  // Shows ONLY users you've actually chatted with
// Shows ONLY users you've actually chatted with
  Widget _buildChatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: service.getUserChats(widget.phone),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text("Error loading chats"),
              ],
            ),
          );
        }

        if (!chatSnapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        var chats = chatSnapshot.data!.docs;

        if (chats.isEmpty) {
          return _buildEmptyChatsState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var chat = chats[index];

            Map<String, dynamic> chatData = chat.data() as Map<String, dynamic>;
            List participants = chatData["participants"] ?? [];

            // Find the other participant (not current user)
            String otherUserId = participants.firstWhere(
                  (id) => id != widget.phone,
              orElse: () => "",
            );

            if (otherUserId.isEmpty) return SizedBox();

            // Get last message info
            String lastMessage = chatData["lastMessage"] ?? "No messages yet";
            Timestamp? lastTime = chatData["lastMessageTime"];

            // Get user details for this chat partner
            return FutureBuilder<DocumentSnapshot>(
              future: service.getUser(otherUserId),
              builder: (context, userSnapshot) {
                // 🔴 FIXED: Handle loading state
                if (!userSnapshot.hasData) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.lightGreen,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.forest,
                        ),
                      ),
                      title: Text("Loading..."),
                    ),
                  );
                }

                // 🔴 FIXED: Handle case when user document doesn't exist or data is null
                if (userSnapshot.data == null || !userSnapshot.data!.exists) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.lightGreen,
                        child: Text(
                          "?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      title: Text("Unknown User"),
                      subtitle: Text("User may have been deleted"),
                      trailing: Icon(
                        Icons.error_outline,
                        color: Colors.orange,
                      ),
                    ),
                  );
                }

                // 🔴 FIXED: Safely cast the data
                var userData;
                try {
                  userData = userSnapshot.data!.data();
                  if (userData == null) {
                    throw Exception("User data is null");
                  }
                  userData = userData as Map<String, dynamic>;
                } catch (e) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.lightGreen,
                        child: Text(
                          "!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      title: Text("Error loading user"),
                      subtitle: Text("Please try again"),
                      trailing: Icon(
                        Icons.refresh,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                // Safe access to user data with fallbacks
                String userName = userData["name"] ?? "Unknown User";
                String userPhone = userData["phone"] ?? otherUserId;

                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.lightGreen,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : "?",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    title: Text(
                      userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        if (lastTime != null)
                          Text(
                            _formatTime(lastTime),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.primary,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            sender: widget.phone,
                            receiver: userPhone,
                            name: userName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  // Empty state widget
  Widget _buildEmptyChatsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "No chats yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Tap the + button to start a new conversation",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format time
  String _formatTime(Timestamp timestamp) {
    if (timestamp == null) return "";
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();

    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return DateFormat.jm().format(dateTime);
    } else if (dateTime.year == now.year) {
      return DateFormat.MMMd().format(dateTime);
    } else {
      return DateFormat.yMMMd().format(dateTime);
    }
  }
}