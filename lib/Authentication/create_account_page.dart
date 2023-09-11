import 'package:facebook/Authentication/adding_user_details_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _verificationId = '';

  Future<void> _verifyPhoneNumber() async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91${_phoneNumberController.text}',
        timeout: Duration(seconds: 60),
        verificationCompleted: (AuthCredential credential) async {
          UserCredential result = await _auth.signInWithCredential(credential);
          User? user = result.user;
          if (user != null) {
            // User is logged in
            print('Logged in as: ${user.uid}');
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => UserDetailsPage(
                mobileNumber: _phoneNumberController.text,
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
        // User is logged in
        // print('Logged in like: ${user.uid}');
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => UserDetailsPage(
              mobileNumber: _phoneNumberController.text,
            )
        )
            );
      } else {
        print('Error logging in');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter Your Mobile Number',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: TextField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyPhoneNumber,
              child: Text('Send OTP'),
            ),
            SizedBox(height: 20),
            Text(
              'Enter OTP sent to your mobile number',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'OTP',
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOTP,
              child: Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
