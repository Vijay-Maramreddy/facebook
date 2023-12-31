import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facebook/Authentication/password_reset.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../base_page.dart';
import '../home/home_page.dart';
import 'create_account_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "FaceBook",
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              AppBar(
                toolbarHeight: 100,
                title: const Center(child: Text("Login Page", style: TextStyle(color: Colors.white, fontSize: 30),)),
                backgroundColor: Colors.blue,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: 600,
                      height: 500,
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Container(height: 110,),
                          Container(
                            alignment: Alignment.centerLeft,
                            child: const Text("FaceBook", style: TextStyle(color: Colors.blue, fontSize: 32),),
                          ),
                          const Text("Facebook helps you connect and share with the people in your life",
                            style: TextStyle(color: Colors.black, fontSize: 24),),
                        ],
                      ),
                    ),
                    const SizedBox(width: 60,),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.black
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.grey, // Shadow color
                            offset: Offset(0, 2), // Offset of the shadow
                            blurRadius: 6, // Blur radius
                            spreadRadius: 4, // Spread radius
                          ),
                        ],

                      ),
                      margin: const EdgeInsets.all(10),
                      alignment: Alignment.center,
                      width: 400,
                      height: 400,
                      child: Column(
                        children: [
                          Container(
                            decoration: customBoxDecoration,
                            margin: const EdgeInsets.all(10),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                            child: TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: "Email",
                              ),
                            ),
                          ),
                          Container(
                            decoration: customBoxDecoration,
                            margin: const EdgeInsets.all(10),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                            child: TextField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: "Password",
                              ),
                            ),
                          ),
                          Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.black
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue,
                              ),
                              margin: const EdgeInsets.all(10),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),

                              child: TextButton(
                                onPressed: () async{
                                  final SharedPreferences sharedPreferences=await SharedPreferences.getInstance();
                                  sharedPreferences.setString('email', _emailController.text);
                                  authenticateUser(_emailController.text, _passwordController.text);
                                },
                                child: const Text("Login", style: TextStyle(color: Colors.white, fontSize: 24),),
                              )
                          ),
                          TextButton(child: const Text("Forgotten Password?"), onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PasswordReset()));
                          }),
                          const Divider(
                            color: Colors.black12, // You can customize the color here
                            thickness: 1,
                            // You can adjust the thickness of the line
                          ),
                          Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.black
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue,
                              ),
                              margin: const EdgeInsets.all(10),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                              child: TextButton(
                                child: const Text("Create New Account", style: TextStyle(color: Colors.white, fontSize: 24),),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CreateAccount(),
                                    ),
                                  );
                                },
                              )

                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> authenticateUser(String email, String password) async {
    try {
      bool isAuthenticated = await authenticateWithEmailAndPassword(email, password);
      print('${isAuthenticated}isAuthenticated');
      if (isAuthenticated) {
        UserData userData = await fetchUserDataByEmail(email);
        print('Authentication successful for user: ${userData.username}');

      } else {
        String message="Authentication failed. Invalid email or password.";
        showAlert(context, message);
        print('Authentication failed. Invalid email or password.');
      }
    } catch (e) {
      print('An error occurred during authentication: $e');
    }
  }

  Future<bool> authenticateWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user=FirebaseAuth.instance.currentUser;
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(user?.uid);
      await userDocRef.update({'isOnline': true});
      Navigator.push(context, MaterialPageRoute(builder: (context)=>HomeScreen(email: email,)));
      return true;
    } on FirebaseAuthException catch (e) {

      print('Failed to authenticate: $e');
      return false;
    }
  }

  Future<UserData> fetchUserDataByEmail(String email) async {
    return UserData(username: '', email: email);
  }
}

class UserData {
  final String username;
  final String email;

  UserData({required this.username, required this.email});
}
