import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facebook/Authentication/create_account_page.dart';
import 'package:facebook/home/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'Authentication/password_reset.dart';
import 'basepage.dart';

Future main() async{
  WidgetsFlutterBinding.ensureInitialized();
  if(kIsWeb){
    await Firebase.initializeApp(
        options:const FirebaseOptions(
            apiKey: "AIzaSyAC2yoMGz2SrRIGrvtMrb-jaBDTTCUETNI",
            appId: "1:957475916382:web:8aede757d4736a6e80c2cf",
            messagingSenderId: "957475916382",
            projectId: "flutter-facebook-4c58a"
        )
    );
  }
  else {
    await Firebase.initializeApp();
  }
  runApp(const MaterialApp(home: MyApp()));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const openScreen();
  }
}

class openScreen extends StatefulWidget {
  const openScreen({super.key});

  @override
  State<openScreen> createState() => _openScreenState();
}

class _openScreenState extends State<openScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:Scaffold(
        body: Center(
          child:Column(
            children: [
              AppBar(
                toolbarHeight: 100,
                title:const Center(child:  Text("Login Page",style: TextStyle(color: Colors.white,fontSize: 30),)),
                backgroundColor: Colors.blue,
              ),
              Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: 600,
                    height: 500,
                    alignment: Alignment.center,
                    child:Column(
                      children: [
                        Container(height: 110,),
                        Container(
                              alignment: Alignment.centerLeft,
                              child: const Text("FaceBook",style: TextStyle(color: Colors.blue,fontSize: 32),),
                        ),
                        Container(
                          child: const Text("Facebook helps you connect and share with the people in your life",style: TextStyle(color: Colors.black,fontSize: 24),),
                        ),
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
                      boxShadow:const  [
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
                            onPressed: (){getUserDataByEmail(_emailController.text,_passwordController.text);},
                            child:const  Text("Login",style: TextStyle(color: Colors.white,fontSize: 24),),
                          )
                        ),
                        Container(
                          child: TextButton(child: const Text("Forgotten Password?"),onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (context)=>PasswordReset()));}),
                        ),
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
                                child:const  Text("Create New Account",style: TextStyle(color: Colors.white,fontSize: 24),),
                                onPressed: (){
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
            ],
          ),
        ),
      ) ,
    );
  }

  // void getUserDataByEmail(TextEditingController email, TextEditingController password) {

    Future<void> getUserDataByEmail(String email, String password) async {
      try {
        // Reference the Firestore collection where user data is stored
        CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

        // Query the collection to find documents that match the provided mobile number
        QuerySnapshot querySnapshot = await usersCollection.where('email', isEqualTo: email).get();

        // Check if any documents match the query
        if (querySnapshot.docs.isNotEmpty) {
          // Access user data (in this example, we assume only one user matches the mobile number)
          DocumentSnapshot userDocument = querySnapshot.docs.first;
          Map<String, dynamic> userData = userDocument.data() as Map<String, dynamic>;

          // You can now use the userData map to access user details
          String password = userData['password'];
          print(password);
          if(password==password){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>HomeScreen()));
          }
          else{
            print("password missmatch");
          }
          // String firstName = userData['firstName'];
          // String lastName = userData['lastName'];
          // String email = userData['email'];
          //
          // // // Use the user data as needed
          // print('First Name: $firstName');
          // print('Last Name: $lastName');
          // print('Email: $email');
        } else {
          // No user found with the provided mobile number
          print('User not found');
        }
      } catch (e) {
        print('Error: $e');
      }
    }
}



