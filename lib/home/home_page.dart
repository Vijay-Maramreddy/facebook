import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facebook/home/show_user_details_page.dart';
import 'package:facebook/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Chat/chat_page.dart';
import '../Posts/status_collection_widget.dart';
import '../app_style.dart';
import '../Posts/image_collection_widget.dart';
import '../base_page.dart';
import '../friend_request_page.dart';

class HomeScreen extends StatefulWidget {
  final String email;

  const HomeScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Uint8List _image;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late String title;
  late Uint8List imageFile;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late bool showOnlyCurrentUserPosts = false;
  late bool status = false;

  List<String> allNames = [];
  List<String> filteredNames = [];
  late String currentUserId;

  void onSearchTextChanged(String searchText) {
    filteredNames.clear();
    if (searchText.isEmpty) {
      setState(() {});
      return;
    }

    for (var name in allNames) {
      if (name.toLowerCase().contains(searchText.toLowerCase())) {
        filteredNames.add(name);
      }
    }

    setState(() {});
  }

  @override
  void initState() {
    fetchUsers();
    User? user = FirebaseAuth.instance.currentUser;
    currentUserId = user!.uid;
    super.initState();
    //
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.person),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShowUserDetailsPage(
                        userId:currentUserId,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.mobile_friendly_rounded),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendRequestPage(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat),
                color: Colors.white, // Customize the color as needed
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage()));
                  // Add your left-end icon onPressed functionality here.
                },
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Center(
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      decoration: customBoxDecoration,
                      margin: const EdgeInsets.all(10),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Column(
                        children: [
                          Stack(children: <Widget>[
                            Container(
                              width: 400,
                              height: 620,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  children: [
                                    TextField(
                                      onChanged: onSearchTextChanged,
                                      decoration: const InputDecoration(
                                        hintText: 'Search',
                                        border: InputBorder.none,
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                    ),
                                    if (filteredNames.isNotEmpty)
                                      Container(
                                          height: 150, // Set a fixed height or adjust as needed
                                          child: ListView.builder(
                                            itemCount: filteredNames.length,
                                            itemBuilder: (context, index) {
                                              return FutureBuilder<DocumentSnapshot?>(
                                                future: fetchData(filteredNames[index]),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return CircularProgressIndicator(); // or a loading indicator
                                                  } else if (snapshot.hasError) {
                                                    return Text('Error: ${snapshot.error}');
                                                  } else if (!snapshot.hasData || snapshot.data == null) {
                                                    return Text('No user found with the specified first name.');
                                                  } else {
                                                    DocumentSnapshot userDocument = snapshot.data!;
                                                    FirebaseAuth auth = FirebaseAuth.instance;
                                                    User? user = auth.currentUser;
                                                    if (userDocument.id == user?.uid) return Container();
                                                    return Container(
                                                      height: 40,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => ShowUserDetailsPage(
                                                                userId: userDocument.id,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              width: 30,
                                                              height: 30,
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                border: Border.all(
                                                                  color: Colors.blue,
                                                                  width: 0.1,
                                                                ),
                                                              ),
                                                              child: ClipOval(
                                                                child: Image.network(
                                                                  userDocument['profileImageUrl'],
                                                                  width: 30,
                                                                  height: 30,
                                                                  fit: BoxFit.cover,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              userDocument['firstName'],
                                                              style: const TextStyle(fontSize: 20),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              );
                                            },
                                          )),
                                    SizedBox(
                                      width: 400,
                                      child: Container(
                                          decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5)), color: Colors.blue),
                                          child: TextButton(
                                              onPressed: uploadImageAndSaveUrl,
                                              child: const Text(
                                                "upload post",
                                                style: TextStyle(color: Colors.white, fontSize: 36),
                                              ))),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 400,
                                      child: Container(
                                          decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5)), color: Colors.blue),
                                          child: TextButton(
                                              onPressed: () {
                                                uploadAStatus();
                                              },
                                              child: const Text(
                                                "Post a Status",
                                                style: TextStyle(color: Colors.white, fontSize: 36),
                                              ))),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 400,
                                      child: Container(
                                          decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5)), color: Colors.blue),
                                          child: TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ShowUserDetailsPage(
                                                      userId: currentUserId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                "User Profile",
                                                style: TextStyle(color: Colors.white, fontSize: 36),
                                              ))),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 400,
                                      child: Container(
                                          decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5)), color: Colors.blue),
                                          child: TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  showOnlyCurrentUserPosts = true;
                                                });
                                              },
                                              child: const Text(
                                                "Your Posts",
                                                style: TextStyle(color: Colors.white, fontSize: 36),
                                              ))),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 400,
                                      child: Container(
                                          decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5)), color: Colors.blue),
                                          child: TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  showOnlyCurrentUserPosts = false;
                                                });
                                              },
                                              child: const Text(
                                                "All Posts",
                                                style: TextStyle(color: Colors.white, fontSize: 36),
                                              ))),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 400,
                                      child: Container(
                                          decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5)), color: Colors.blue),
                                          child: TextButton(
                                              onPressed: () => _signOut(context),
                                              child: const Text(
                                                "Log Out",
                                                style: TextStyle(color: Colors.white, fontSize: 36),
                                              ))),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  Column(children: [
                    Center(
                      child: Container(color: Colors.white, child: StatusCollectionWidget(showOnlyCurrentUserPosts: showOnlyCurrentUserPosts)),
                    ),
                    Center(
                      child: Container(color: Colors.white, child: ImageCollectionWidget(showOnlyCurrentUserPosts: showOnlyCurrentUserPosts)),
                    ),
                  ]),
                  // Align(
                  //   alignment: Alignment.topLeft,
                  //     child: IconButton(onPressed: (){}, icon: Icon(Icons.send))
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _auth.signOut();
      // Navigate to the login or home page after sign out
      // Replace with the appropriate route in your app
      Navigator.push(context, MaterialPageRoute(builder: (context) => openScreen()));
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  Future<Uint8List> pickImageFromGallery() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    _image = img;
    return _image;
  }

  Future<void> addImageUrlToFirebase(String userId, String imageUrl, String title, int likes, int commentsCount, String dateTime,
      List<String> likedBy, String profileImageUrl, String firstName, bool status) async {
    final CollectionReference imagesCollection = FirebaseFirestore.instance.collection('images');

    // Add a new document to the 'images' collection
    await imagesCollection.add({
      'imageUrl': imageUrl,
      'userId': userId,
      'title': title,
      'likes': likes,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'dateTime': dateTime,
      'profileImageUrl': profileImageUrl,
      'firstName': firstName,
      'status': status,
    });
  }

  void uploadImageAndSaveUrl() async {
    imageFile = await pickImageFromGallery();

    if (imageFile != null) {
      String? title = await _showImagePickerDialog();
      int likes = 0;

      List<String> likedBy = [];
      late String profileImageUrl;
      late String firstName;
      int commentsCount = 0;
      String uuid = AppStyles.uuid();
      DateTime now = DateTime.now();
      String dateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);
      String? imageUrl = await uploadImageToStorage('postImages/' + uuid, imageFile);
      if (imageUrl != null) {
        // Use the Firebase auth user's UID as the user ID
        CollectionReference usersCollection = await FirebaseFirestore.instance.collection('users');
        // // Query the collection to find documents that match the provided mobile number
        // DocumentSnapshot documentSnapshot = await usersCollection.doc(user.uid).get();
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          DocumentSnapshot documentSnapshot = await usersCollection.doc(user.uid).get();
          if (documentSnapshot.exists) {
            Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;
            if (data != null) {
              profileImageUrl = data['profileImageUrl'];
              firstName = data['firstName'];
            } else {
              print('Document data is null.');
            }
          } else {
            String message = "user details not found";
            showAlert(context, message);
          }
          await addImageUrlToFirebase(user.uid, imageUrl, title!, likes, commentsCount, dateTime, likedBy, profileImageUrl, firstName, status);
          setState(() {});
        } else {
          print('Error: User is not authenticated.');
        }
      } else {
        print('Error uploading image.');
      }
    } else {
      print('No image picked.');
    }
  }

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String?> _showImagePickerDialog() async {
    if (imageFile != null) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          title = '';

          return AlertDialog(
            title: const Text('Assign a Title'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(imageFile),
                TextField(
                  onChanged: (value) {
                    title = value;
                  },
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, title);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      return title;
    } else {
      return '';
    }
  }

  void uploadAStatus() {
    status = true;
    uploadImageAndSaveUrl();
  }

  void fetchUsers() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').get();

    for (QueryDocumentSnapshot document in querySnapshot.docs) {
      // Access the firstName field from each document and add it to the list
      var firstName = document['firstName'];
      if (firstName != null) {
        allNames.add(firstName.toString());
      }
    }
  }

  Future<DocumentSnapshot?> fetchData(String firstName) async {
    DocumentSnapshot? userDocument = await getDocumentByFirstName(firstName);

    if (userDocument != null) {
      // Document found, print the data
      print('User found');
    } else {
      print('No user found with the specified first name.');
    }
    return userDocument;
  }

  // import 'package:cloud_firestore/cloud_firestore.dart';

  Future<DocumentSnapshot?> getDocumentByFirstName(String firstName) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where('firstName', isEqualTo: firstName).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        // If a document is found, return the first one
        return querySnapshot.docs.first;
      } else {
        // No document found with the specified firstName
        return null;
      }
    } catch (e) {
      print('Error retrieving document by first name: $e');
      return null;
    }
  }
}
