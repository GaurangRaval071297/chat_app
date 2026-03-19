import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../App Clolor/app_color.dart';
import 'firebase_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart'; // Add this import

class ChatDashboard extends StatefulWidget {
  final String email;
  ChatDashboard({required this.email});

  @override
  _ChatDashboardState createState() => _ChatDashboardState();
}

class _ChatDashboardState extends State<ChatDashboard> {
  FirebaseService service = FirebaseService();
  String? name;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  _loadName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => name = prefs.getString("name") ?? widget.email);
  }

  // Add logout method
  Future<void> _logout() async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('name');

      if (mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Chats", style: TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.appBarBackground,
        // Add logout button in app bar
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.textLight),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No users found"));
          }

          // Filter out current user and get data safely
          var users = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>?;
            return data != null && data['email'] != widget.email;
          }).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var doc = users[index];
              var userData = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.lightGreen,
                  child: Text(
                    (userData['name']?.isNotEmpty == true)
                        ? userData['name'][0].toUpperCase()
                        : '?',
                    style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  userData['name'] ?? 'Unknown',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  userData['email'] ?? '',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        sender: widget.email,
                        receiver: userData['email'],
                        name: userData['name'] ?? 'Unknown',
                        email: userData['email'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}