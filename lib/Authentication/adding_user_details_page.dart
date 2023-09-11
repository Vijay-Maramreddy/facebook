
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        builder: (context) => HomeScreen(),
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
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            TextFormField(
              controller: _ageController,
              decoration: InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            TextFormField(
              controller: _genderController,
              decoration: InputDecoration(labelText: 'Gender'),
            ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

