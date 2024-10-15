import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseOptions options = const FirebaseOptions(
    apiKey: 'AIzaSyAMMqxrCRZZ7zz1n8WypcTPsPwTgak_I7E',
    appId: '1:377130403323:android:4e22c23712693ede88775e',
    projectId: 'incomeexpenses-9d8b5',
    messagingSenderId: '377130403323',
    storageBucket: 'incomeexpenses-9d8b5.appspot.com',
  );
  await Firebase.initializeApp(options: options);
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
