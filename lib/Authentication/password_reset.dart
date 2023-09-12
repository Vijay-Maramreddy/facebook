import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'adding_user_details_page.dart';

class PasswordReset extends StatefulWidget {
  const PasswordReset({super.key});

  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _verificationId = '';
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Reset'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Your Mobile Number:'),
            TextFormField(
              controller: _mobileNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                getUserDataByMobileNumber(_mobileNumberController.text);
              },
              child: const Text('Send OTP'),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOTP,
              child: const Text('Verify OTP'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                updatePasswordByMobileNumber(
                  _mobileNumberController.text,
                  _passwordController.text,
                );
              },
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getUserDataByMobileNumber(String mobile) async {
    try {
      CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

      QuerySnapshot querySnapshot =
      await usersCollection.where('mobileNumber', isEqualTo: mobile).get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDocument = querySnapshot.docs.first;
        Map<String, dynamic> userData =
        userDocument.data() as Map<String, dynamic>;
        print("User found");
        String message = "User is found";
        showAlert(context, message);

        _verifyPhoneNumber();
      } else {
        print('User not found');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _verifyPhoneNumber() async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91${_mobileNumberController.text}',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (AuthCredential credential) async {
          UserCredential result = await _auth.signInWithCredential(credential);
          User? user = result.user;
          if (user != null) {
            print('Logged in as: ${user.uid}');
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => UserDetailsPage(
                mobileNumber: _mobileNumberController.text,
              ),
            ));
          } else {
            print('Error logging in');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Error: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            String message = "OTP is sent to the registered mobile number";
            showAlert(context, message);
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _verifyOTP() async {
    try {
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        print("OTP verified successfully");
        String message = "OTP is verified and now you can update the password";
        showAlert(context, message);
      } else {
        print('OTP verification failed');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> updatePasswordByMobileNumber(
      String mobileNumber, String newPassword) async {
    try {
      final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

      QuerySnapshot mobileNumberQuery =
      await usersCollection.where('mobileNumber', isEqualTo: mobileNumber).get();

      for (QueryDocumentSnapshot docSnapshot in mobileNumberQuery.docs) {
        DocumentReference docRef = usersCollection.doc(docSnapshot.id);

        await docRef.update({'password': newPassword});
        print("Password updated successfully");
      }
      Navigator.push(context, MaterialPageRoute(builder: (context) => openScreen()));
    } catch (e) {
      print('Error updating password: $e');
    }
  }
}

void showAlert(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Alert'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
