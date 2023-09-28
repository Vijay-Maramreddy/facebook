import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facebook/home/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../app_style.dart';
import '../base_page.dart';

class ShowUserDetailsPage extends StatefulWidget {
  final String? email;
  final String? userId;
  const ShowUserDetailsPage({super.key, this.email, this.userId});

  @override
  _ShowUserDetailsPageState createState() => _ShowUserDetailsPageState();
}

class _ShowUserDetailsPageState extends State<ShowUserDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Uint8List? _image;
  late String errorMessage;
  late String imageUrl;
  late String loadImageUrl = '';

  FirebaseAuth auth = FirebaseAuth.instance;

  bool friendStatus = false;
  bool requestStatus = false;
  late String requestId;
  late String requestedTo;
  late String requestedBy;

  bool editable = false;

  @override
  void initState() {
    loadFriendsStatus();
    loadUserDetails();
    print('hi');
    super.initState();
  }

  void savedata() async {
    String uuid = AppStyles.uuid();
    imageUrl = await uploadImageToStorage('profileImage/' + uuid, _image!);
    Map<String, dynamic> updatedData = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'age': _ageController.text,
      'location': _locationController.text,
      'gender': _genderController.text,
      'email': _emailController.text,
      'profileImageUrl': imageUrl, // Add the image URL to user data
    };
    try {
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

      // Query the collection to find documents that match the provided email
      QuerySnapshot querySnapshot = await usersCollection.where('email', isEqualTo: widget.email).get();

      if (querySnapshot.docs.isNotEmpty) {
        print("while upadting profile image 2");
        User? user = FirebaseAuth.instance.currentUser;
        String? CurrentuserId = user?.uid;

        print(widget.userId);
        DocumentSnapshot userDocument = querySnapshot.docs.first;
        await usersCollection.doc(CurrentuserId).update(updatedData);
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(email: _emailController.text)));
      } else {
        String message = "User details not found";
        showAlert(context, message);
      }
    } catch (e) {
      // Handle any errors that may occur during the update process.
      print("Error updating user details: $e");
      errorMessage = "An error occurred while updating user details";
      showAlert(context, errorMessage);
    }
  }

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    print("inside upload image to storage");
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    print("end of upload image to storage");
    return downloadUrl;
  }

  Future<void> selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }

  void loadUserDetails() async {
    print("loading user detials");
    print(widget.userId);
    if (widget.email != null) {
      editable = true;
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
      QuerySnapshot querySnapshot = await usersCollection.where('email', isEqualTo: widget.email).get();
      if (querySnapshot.docs.isNotEmpty) {
        print("hii");

        DocumentSnapshot userDocument = querySnapshot.docs.first;
        setState(() {
          print("inside set state of loaduserdetails email ");
          _firstNameController.text = userDocument['firstName'] ?? '';
          _lastNameController.text = userDocument['lastName'] ?? '';
          _emailController.text = userDocument['email'] ?? '';
          _locationController.text = userDocument['location'] ?? '';
          _ageController.text = userDocument['age'] ?? '';
          _genderController.text = userDocument['gender'] ?? '';
          loadImageUrl = userDocument['profileImageUrl'] ?? '';
        });
      } else {
        String message = "user details not found";
        showAlert(context, message);
      }
    } else {
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
      print(widget.userId);
      // Query the collection to find the document with the provided UID
      var userDocument = await usersCollection.doc(widget.userId).get();
      if (userDocument.exists) {
        setState(() {
          print("inside set state of loaduserdetails ");
          _firstNameController.text = userDocument['firstName'] ?? '';
          _lastNameController.text = userDocument['lastName'] ?? '';
          _emailController.text = userDocument['email'] ?? '';
          _locationController.text = userDocument['location'] ?? '';
          _ageController.text = userDocument['age'] ?? '';
          _genderController.text = userDocument['gender'] ?? '';
          loadImageUrl = userDocument['profileImageUrl'] ?? '';
        });
      } else {
        String message = "user details not found";
        showAlert(context, message);
      }
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: selectImage,
                child: Container(
                  width: 200, // Increased width
                  height: 200, // Increased height
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue,
                      width: 2.0,
                    ),
                  ),
                  child: _image != null
                      ? ClipOval(
                          child: Image.memory(
                            _image!,
                            width: 200, // Increased width
                            height: 200, // Increased height
                            fit: BoxFit.cover,
                          ),
                        )
                      : loadImageUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                loadImageUrl!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 80, // Increased size
                              color: Colors.blue,
                            ),
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      enabled: editable,
                      cursorColor: Colors.purple,
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
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
                      enabled: editable,
                      cursorColor: Colors.purple,
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
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
                      enabled: editable,
                      cursorColor: Colors.purple,
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
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
                      enabled: editable,
                      cursorColor: Colors.purple,
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
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
                      enabled: editable,
                      cursorColor: Colors.purple,
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
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
                      enabled: editable,
                      cursorColor: Colors.purple,
                      controller: _genderController,
                      decoration: InputDecoration(
                        labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
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
                    Visibility(
                      visible: editable,
                      child: SizedBox(
                        height: 40,
                        width: 120,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.all(5),
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: savedata,
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                            child: Text('Save'),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: !editable,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Visibility(
                              visible: !requestStatus,
                              child: ElevatedButton(
                                  onPressed: () {
                                    sendFriendrequest();
                                  },
                                  child: Text("Send Friend Request"))),
                          Visibility(
                              visible: requestStatus && !friendStatus,
                              child: Row(children: [
                                const Text("Request Sent "),
                                ElevatedButton(
                                    onPressed: () {
                                      cancelRequest;
                                    },
                                    child: Text("Cancel request"))
                              ])),
                          Visibility(visible: friendStatus, child: ElevatedButton(onPressed: () {}, child: Text("Remove Friend"))),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  sendFriendrequest() {
    User? user = auth.currentUser;
    requestedBy = user!.uid;
    requestedTo = widget.userId!;
    friendStatus = false;
    requestStatus = true;
    requestId = createRequestId(requestedBy, requestedTo);
    CollectionReference friendRequests = FirebaseFirestore.instance.collection('friendRequests');

    friendRequests.add({
      'friendStatus': friendStatus,
      'requestStatus': requestStatus,
      'requestId': requestId,
      'requestedBy': requestedBy,
      'requestedTo': requestedTo,
    });
    setState(() {
      friendStatus = false;
      requestStatus = true;
    });
  }

        cancelRequest() async {
    User? user = auth.currentUser;
    requestedBy = user!.uid;
    requestedTo = widget.userId!;
    friendStatus = false;
    requestStatus = false;
    requestId = createRequestId(requestedBy, requestedTo);
    CollectionReference friendRequests = FirebaseFirestore.instance.collection('friendRequests');

    QuerySnapshot querySnapshot = await friendRequests.where('requestId', isEqualTo: requestId).get();
    for (QueryDocumentSnapshot document in querySnapshot.docs) {
      await friendRequests.doc(document.id).delete();
      print('Document deleted: ${document.id}');
      setState(() {});
    }
  }

  String createRequestId(String requestedBy, String requestedTo) {
    return combineIds(requestedBy, requestedTo);
  }

  Future<void> loadFriendsStatus() async {
    print('inside LFR');
    User? user = auth.currentUser;
    requestedBy = user!.uid;
    requestedTo = widget.userId!;
    requestId = createRequestId(requestedBy, requestedTo);
    CollectionReference friendRequests = FirebaseFirestore.instance.collection('friendRequests');

    QuerySnapshot querySnapshot = await friendRequests.where('requestId', isEqualTo: requestId).where('requestedBy', isEqualTo: requestedBy).get();

    if (querySnapshot.docs.isNotEmpty) {
      print('querySnapshot is not empty');

      querySnapshot.docs.forEach((doc) {
        // friendStatus=doc['friendStatus'];
        requestStatus = doc['requestStatus'];
      });
    } else {
      print('No friend request found with requestId: $requestId');
    }
  }
}
