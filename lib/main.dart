import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facebook/Authentication/create_account_page.dart';
import 'package:facebook/Authentication/login_page.dart';
import 'package:facebook/home/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Authentication/password_reset.dart';
import 'base_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyAC2yoMGz2SrRIGrvtMrb-jaBDTTCUETNI",
            authDomain: "flutter-facebook-4c58a.firebaseapp.com",
            projectId: "flutter-facebook-4c58a",
            storageBucket: "flutter-facebook-4c58a.appspot.com",
            messagingSenderId: "957475916382",
            appId: "1:957475916382:web:8aede757d4736a6e80c2cf",
            measurementId: "G-TLKZZM2KR6"));
  } else {
    await Firebase.initializeApp();
  }
  runApp(MaterialApp(title: 'FaceBook',home: MyApp(),));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceBook',
      builder: (context, child) => openScreen(),
    );
  }
}

class openScreen extends StatefulWidget {
  const openScreen({super.key});

  @override
  State<openScreen> createState() => _openScreenState();
}

class _openScreenState extends State<openScreen> {
  // final TextEditingController _emailController = TextEditingController();
  // final TextEditingController _passwordController = TextEditingController();

  late final finalEmail;

  @override
  void initState() {
    getValidationData().whenComplete(() async {
      finalEmail == null
          ? (Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage())))
          : (Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(email: finalEmail))));
    });
    super.initState();
  }

  Future getValidationData() async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var obtainedEmail = sharedPreferences.get('email');
    setState(() {
      finalEmail = obtainedEmail;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox();
  }
}


