import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../App Clolor/app_color.dart';
import 'dashboard.dart';
import 'firebase_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  FirebaseService service = FirebaseService();
  bool isLoading = false;

  void loginUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter both email and password"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      var userSnapshot = await service.getUser(email);
      if (!userSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user found"), backgroundColor: Colors.red),
        );
        setState(() => isLoading = false);
        return;
      }

      var userData = userSnapshot.data() as Map<String, dynamic>?;

      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User data not found"), backgroundColor: Colors.red),
        );
        setState(() => isLoading = false);
        return;
      }

      if (userData['password'] != password) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Incorrect password"), backgroundColor: Colors.red),
        );
        setState(() => isLoading = false);
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("email", email);
      await prefs.setString("name", userData['name'] ?? "");

      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ChatDashboard(email: email))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Login", style: TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.appBarBackground,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : loginUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Login", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen())
              ),
              child: Text(
                "Don't have an account? Register",
                style: TextStyle(color: AppColors.primary),
              ),
            )
          ],
        ),
      ),
    );
  }
}