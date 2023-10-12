import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facebook/home/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import '../app_style.dart';
import '../base_page.dart';

class ShowUserDetailsPage extends StatefulWidget {
  final String? userId;
  const ShowUserDetailsPage({super.key, this.userId});

  @override
  _ShowUserDetailsPageState createState() => _ShowUserDetailsPageState();
}

class _ShowUserDetailsPageState extends State<ShowUserDetailsPage> {
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
  late String finalImage;
  late List<String> blockedList=[];

  FirebaseAuth auth = FirebaseAuth.instance;

  bool friendStatus = false;
  bool requestStatus = false;
  late String requestId;
  late String requestedTo;
  late String requestedBy;

  bool editable = false;
  bool isUser = false;
  bool isBlocked=false;

  @override
  void initState() {
    loadFriendsStatus();
    loadUserDetails();
    updateEditable();
    blocked();
    super.initState();
  }

  void savedata() async {
    if (_image != null) {
      String uuid = AppStyles.uuid();
      imageUrl = await uploadImageToStorage('profileImage/$uuid', _image!);
    } else {
      imageUrl = loadImageUrl;
    }

    Map<String, dynamic> updatedData = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'age': _ageController.text,
      'location': _locationController.text,
      'gender': _genderController.text,
      'email': _emailController.text,
      'profileImageUrl': imageUrl,
    };

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String? id = widget.userId;
      DocumentReference documentReference = firestore.collection('users').doc(widget.userId);

      await documentReference.update(updatedData);
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(email: _emailController.text)));
        } catch (e) {
      print("Error updating user details: $e");
      errorMessage = "An error occurred while updating user details";
      showAlert(context, errorMessage);
    }
  }

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }

  void loadUserDetails() async {
    print(widget.userId);
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
    var userDocument = await usersCollection.doc(widget.userId).get();
    if (userDocument.exists) {
      setState(() {
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
                      : loadImageUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                loadImageUrl,
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
                          onPressed: () {
                            savedata();
                          },
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
                              visible: !(requestStatus || friendStatus),
                              child: ElevatedButton(
                                  onPressed: () {
                                    sendFriendrequest();
                                  },
                                  child: const Text("Send Friend Request"))),
                          Visibility(
                              visible: requestStatus && !friendStatus,
                              child: Row(children: [
                                const Text("Request Sent "),
                                ElevatedButton(
                                    onPressed: () {
                                      cancelRequest();
                                    },
                                    child: const Text("Cancel request"))
                              ])),
                          Visibility(
                              visible: friendStatus,
                              child: ElevatedButton(
                                  onPressed: () {
                                    removeFriend();
                                  },
                                  child: const Text("Remove Friend")
                              )
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20,),
                    Visibility(
                        visible: !editable,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Visibility(
                                visible: !isBlocked,
                                child: ElevatedButton(
                                    onPressed: () {
                                      addToBlocked();
                                    },
                                    child: const Text("Block"),
                                )
                            ),
                            Visibility(
                                visible: isBlocked,
                                child: ElevatedButton(
                                    onPressed: () {
                                      removeFromBlocked();
                                    },
                                    child: const Text("UnBlock"),
                                )
                            ),
                          ],
                        )
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

  removeFriend() async {
    User? user = auth.currentUser;
    requestedBy = user!.uid;
    requestedTo = widget.userId!;
    friendStatus = false;
    requestStatus = false;
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(requestedTo);
    userDoc.get().then((DocumentSnapshot userSnapshot) {
      if (userSnapshot.exists) {
        List<String> friendsList = [];

        if (userSnapshot['friends'] is List) {
          friendsList = List.from(userSnapshot['friends']);
        }
        friendsList.remove(requestedBy);

        userDoc.set({'friends': friendsList}, SetOptions(merge: true));
      } else {
        userDoc.set({
          'Not friends': [requestedBy]
        });
      }
    }).catchError((e) {
      print('Error getting user document: $e');
    });
    DocumentReference usersDoc = FirebaseFirestore.instance.collection('users').doc(requestedBy);
    usersDoc.get().then((DocumentSnapshot userSnapshot) {
      if (userSnapshot.exists) {
        List<String> friendsList = [];

        if (userSnapshot['friends'] is List) {
          friendsList = List.from(userSnapshot['friends']);
        }
        friendsList.remove(requestedTo);

        usersDoc.set({'friends': friendsList}, SetOptions(merge: true));
      } else {
        usersDoc.set({
          'Not friends': [requestedTo]
        });
      }
    }).catchError((e) {
      print('Error getting user document: $e');
    });
  }

  String createRequestId(String requestedBy, String requestedTo) {
    return combineIds(requestedBy, requestedTo);
  }

  Future<void> loadFriendsStatus() async {
    User? user = auth.currentUser;
    requestedBy = user!.uid;
    requestedTo = widget.userId!;
    requestId = createRequestId(requestedBy, requestedTo);
    CollectionReference friendRequests = FirebaseFirestore.instance.collection('friendRequests');

    QuerySnapshot querySnapshot = await friendRequests.where('requestId', isEqualTo: requestId).where('requestedBy', isEqualTo: requestedBy).get();

    if (querySnapshot.docs.isNotEmpty) {

      for (var doc in querySnapshot.docs) {
        friendStatus = doc['friendStatus'];
        requestStatus = doc['requestStatus'];
      }
    } else {
      print('No friend request found with requestId: $requestId');
    }
    DocumentSnapshot userDocument = await FirebaseFirestore.instance.collection('users').doc(requestedTo).get();
    if (userDocument.exists) {
      List<dynamic> friends = userDocument['friends'];

      if (friends != null && friends.contains(requestedBy)) {
        friendStatus = true;
      }
    }
  }

  void updateEditable() {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    if (widget.userId == currentUserId) {
      editable = true;
    }
  }

  void blocked() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
    var userDocument = await usersCollection.doc(currentUserId).get();
    if(userDocument['blocked'].contains(widget.userId))
      {
        isBlocked=true;
      }
    else {
      isBlocked=false;
    }
  }

  Future<void> addToBlocked() async {
    // Get the document reference
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    DocumentReference documentReference =
    FirebaseFirestore.instance.collection('users').doc(currentUserId);


    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
      await documentReference.get() as DocumentSnapshot<Map<String, dynamic>>;
      if (documentSnapshot.exists) {
        List<String> blockedList = List<String>.from(documentSnapshot.data()!['blocked']);
        blockedList.add(widget.userId!);

        // Update the document with the modified blocked list
        await documentReference.update({'blocked': blockedList});
        setState(() {
          isBlocked=true;
        });
      } else {
        print('Document with ID $currentUserId not found.');
      }
    } catch (e) {
      print('Error adding to blocked list and updating document: $e');
    }
    String message=" blocked ";
    sendMessageOrIcon(message);
  }

  Future<void> removeFromBlocked() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    DocumentReference documentReference =
    FirebaseFirestore.instance.collection('users').doc(currentUserId);
    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
      await documentReference.get() as DocumentSnapshot<Map<String, dynamic>>;
      if (documentSnapshot.exists) {
        List<String> blockedList = List<String>.from(documentSnapshot.data()!['blocked']);
        blockedList.remove(widget.userId!);
        await documentReference.update({'blocked': blockedList});
        setState(() {
          isBlocked=false;
        });
      } else {
        print('Document with ID $currentUserId not found.');
      }
    } catch (e) {
      print('Error adding to blocked list and updating document: $e');
    }
    String message=" unblocked ";
    sendMessageOrIcon(message);
  }

  void sendMessageOrIcon(String message) async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;

    CollectionReference messageCount = FirebaseFirestore.instance.collection('messageCount');

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await messageCount
        .where('interactedBy', isEqualTo: currentUserId)
        .where('interactedTo', isEqualTo:widget.userId )
        .get() as QuerySnapshot<Map<String, dynamic>>;
    DocumentSnapshot<Map<String, dynamic>> doc = querySnapshot.docs.first;
    int count = doc['count'];
    count = count + 1;
    await doc.reference.update({'count': count});
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    String? imageUrl = '';
    String groupId = combineIds(currentUserId, widget.userId);
    if (message.isNotEmpty) {
      await interactionsCollection.add({
        'interactedBy': currentUserId,
        'interactedWith': widget.userId,
        'imageUrl': imageUrl,
        'dateTime': formattedDateTime,
        'message': "",
        'groupId': groupId,
        'videoUrl': '',
        'visibility':true,
        'baseText':message,
      });
    }
  }
}
