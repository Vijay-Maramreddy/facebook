
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../basepage.dart';
import '../home/home_page.dart';


class UserDetailsPage extends StatefulWidget {
  final String mobileNumber;

  UserDetailsPage({required this.mobileNumber});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _registerUser() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Get the UID of the newly created user
      String uid = userCredential.user!.uid;

      // Store additional user details in Firestore
      await _firestore.collection('users').doc(uid).set({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'age': _ageController.text,
        'location': _locationController.text,
        'gender': _genderController.text,
        'mobileNumber': widget.mobileNumber,
        'email':_emailController.text,
        'password':_passwordController.text,
      });

      // Navigate to the home page or another screen
      // For example:
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ));
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              'Mobile Number: ${widget.mobileNumber}',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Container(
              decoration: customBoxDecoration,
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: "First Name",
                ),
              ),
            ),
            Container(
              decoration: customBoxDecoration,
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: "Last Name",
                ),
              ),
            ),
            Container(
              decoration: customBoxDecoration,
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: TextField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: "Age",
                ),
              ),
            ),
            Container(
              decoration: customBoxDecoration,
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Location",
                ),
              ),
            ),
            Container(
              decoration: customBoxDecoration,
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: TextField(
                controller: _genderController,
                decoration: const InputDecoration(
                  labelText: "Gender",
                ),
              ),
            ),
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
                obscureText: true,
              ),
            ),
            Container(
              decoration: customBoxDecoration,
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                ),
                obscureText: true,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                autofocus: mounted,
                onPressed: _registerUser,
                child: Text('Register',style: TextStyle(color: Colors.white,fontSize: 32),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

