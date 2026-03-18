import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.android,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(MaterialApp(
    title: 'Chat App',
    theme: ThemeData(
      primarySwatch: Colors.green,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAX2WcLtoUjg_WTbCeg85-2z7tOD0Y4cZ4',
    appId: '1:76050610669:android:1b31a31ae32f2613470fe4',
    messagingSenderId: '76050610669',
    projectId: 'chatapp-98561',
    storageBucket: 'chatapp-98561.firebasestorage.app',
  );
}