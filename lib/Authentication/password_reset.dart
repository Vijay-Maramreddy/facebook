import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../base_page.dart';
import '../main.dart';
import 'adding_user_details_page.dart';

class PasswordReset extends StatefulWidget {
  const PasswordReset({super.key});

  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _verificationId = '';
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _otpSent = false;
  bool _otpVerified=false;

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
            const Text('Enter Your Mobile Number:',style: TextStyle(fontSize: 24),),
            Container(
              decoration: customBoxDecoration,
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: TextField(
                controller: _mobileNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Enter Registered Mobile Number",
                ),
              ),
            ),

            const SizedBox(height: 20),
            Visibility(
              visible: !_otpSent,
              child: ElevatedButton(
                onPressed: () {
                  getUserDataByMobileNumber(_mobileNumberController.text);
                },
                child: const Text('Send OTP',style: TextStyle(fontSize: 24),),
              ),
            ),
            const SizedBox(height: 20),
            if(_otpSent)
              Column(
                children: [
                  Container(
                    decoration: customBoxDecoration,
                    margin: const EdgeInsets.all(10),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Enter OTP",
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Visibility(
                    visible: !_otpVerified,
                    child: ElevatedButton(
                      onPressed: _verifyOTP,
                      child: const Text('Verify OTP'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if(_otpVerified)
                    Column(
                      children: [
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
                        const SizedBox(height: 20),
                        Container(
                          decoration: customBoxDecoration,
                          margin: const EdgeInsets.all(10),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: TextField(
                            controller: _confirmPasswordController,
                            // keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: "Confirm Password",
                            ),
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_passwordController.text == _confirmPasswordController.text) {
                              // Passwords match, call your function here
                              updatePasswordByMobileNumber(
                                _mobileNumberController.text,
                                _passwordController.text,
                              );
                            } else {
                              // Passwords don't match, show an alert message
                              String message = "Password and Confirm Password do not match";
                              showAlert(context, message);
                            }
                          },
                          child: const Text('Reset Password'),
                        ),

                      ],
                    ),

                ],
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
        _otpSent = true;


        _verifyPhoneNumber();
      } else {
        String message = "User is not found";
        showAlert(context, message);
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

        _otpVerified=true;
        setState(() {
          _otpVerified = true; // Update the UI to show the password reset fields
        });
      } else {
        String message = "OTP missmatch and verified and verification is failed";
        showAlert(context, message);
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
      }
      Navigator.push(context, MaterialPageRoute(builder: (context) => openScreen()));
    } catch (e) {
      print('Error updating password: $e');
    }
  }
  // Future<void> passwordMatch(String password,String confirmpassword,Function? onPressed) async{
  //   if(password==confirmpassword){
  //     setState(() {
  //       onPressed;
  //     });
  //   }else{
  //     String message = "password and conformPassword doesnot match";
  //     showAlert(context, message);
  //   }
  // }
}


