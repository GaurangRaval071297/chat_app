import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  void checkLogin() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? phone = prefs.getString("phone");
    String? email = prefs.getString("email");

    Timer(Duration(seconds: 3), () {

      if(email != null){

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDashboard(email: email),
          ),
        );

      } else {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );

      }

    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB7E4C7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Lottie.asset(
              'assets/lottie_animation/chatbot.json',
              height: 200,
            ),

            SizedBox(height: 20),

            Text(
              "Chat App",
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Connect with friends ",
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}