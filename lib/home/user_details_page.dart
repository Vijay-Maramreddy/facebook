import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class ShowUserDetailsPage extends StatefulWidget {
  const ShowUserDetailsPage({super.key});

  @override
  _ShowUserDetailsPageState createState() => _ShowUserDetailsPageState();
}

class _ShowUserDetailsPageState extends State<ShowUserDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ageController= TextEditingController();
  final TextEditingController _genderController= TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  void _saveUserDetails() async {
    String documentId;
    User? user = FirebaseAuth.instance.currentUser;
    if(user!= null) {
      // User is signed in; you can access the user's unique ID
      documentId = user.uid;
      await _firestore.collection('users').doc(documentId).update({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'age': _ageController.text,
        'location': _locationController.text,
        'gender': _genderController.text,
        'email':_emailController.text,
      });
      Navigator.pop(context);

    }
  }

  @override
  void initState() {
    super.initState();
    // Load user details if updating existing user
    loadUserDetails();
  }

  void loadUserDetails() async {
    String documentId;
    User? user = FirebaseAuth.instance.currentUser;
    if(user!= null) {
  // User is signed in; you can access the user's unique ID
      documentId = user.uid;
      print(documentId);
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
      await usersCollection.doc(documentId).get().then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
          print(data);

          setState(() {
            print("inside set state");
            _firstNameController.text = data['firstName'] ?? '';
            _lastNameController.text = data['lastName'] ?? '';
            _emailController.text = data['email'] ?? '';
            _locationController.text =data['location'] ?? '';
            _ageController.text =data['age'] ?? '';
            _genderController.text =data['gender'] ?? '';
          });
        }
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                cursorColor: Colors.purple,
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color:Colors.black, fontSize: 12),
                  labelText: 'First Name',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.purple),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                cursorColor: Colors.purple,
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color:Colors.black, fontSize: 12),
                  labelText: 'Last Name',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.purple),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                cursorColor: Colors.purple,
                controller: _emailController,
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color:Colors.black, fontSize: 12),
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.purple),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                cursorColor: Colors.purple,
                controller: _locationController,
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color:Colors.black, fontSize: 12),
                  labelText: 'Location',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.purple),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                cursorColor: Colors.purple,
                controller: _ageController,
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color:Colors.black, fontSize: 12),
                  labelText: 'Age',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.purple),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                cursorColor: Colors.purple,
                controller: _genderController,
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color:Colors.black, fontSize: 12),
                  labelText: 'Gender',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.purple),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your gender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              SizedBox(
                height: 40,
                width: 120,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(5),
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _saveUserDetails,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                    child: Text('Save'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

