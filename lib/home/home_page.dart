
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
  late bool showOnlyCurrentUserPosts=false;
  late bool status=false;

  @override
  void initState() {
    super.initState();
    //
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            color: Colors.blue,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShowUserDetailsPage(
                    email: widget.email,
                  ),
                ),
              );
            },
          ),
        ],
        flexibleSpace: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chat),
              color: Colors.white, // Customize the color as needed
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const ChatPage()));
                // Add your left-end icon onPressed functionality here.
              },
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white, // Customize the background color as needed
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.lightBlueAccent,
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children:[ SingleChildScrollView(
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
                        Container(
                          child: Image.network(
                            'https://w7.pngwing.com/pngs/788/714/png-transparent-logo-facebook-social-media-business-restaurant-menu-books-blue-text-trademark.png',
                            width: 400,
                            height: 200,
                          ),
                        ),
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
                                  onPressed:(){
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
                                          email: widget.email,
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
                                  onPressed:(){setState(() {
                                    showOnlyCurrentUserPosts=true;
                                  });} ,
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
                                  onPressed:(){setState(() {
                                    showOnlyCurrentUserPosts=false;
                                  });} ,
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
                Column(
                  children:[
                    Center(
                      child: Container(
                        color: Colors.white,
                        child: StatusCollectionWidget(showOnlyCurrentUserPosts: showOnlyCurrentUserPosts)
                      ),
                    ),
                    Center(
                      child: Container(
                        color: Colors.white,
                        child: ImageCollectionWidget(showOnlyCurrentUserPosts: showOnlyCurrentUserPosts)
                      ),
                    ),
                  ]
                ),
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

  Future<void> addImageUrlToFirebase(String userId, String imageUrl, String title, int likes,int commentsCount, String dateTime, List<String> likedBy, String profileImageUrl, String firstName, bool status) async {
    final CollectionReference imagesCollection = FirebaseFirestore.instance.collection('images');

    // Add a new document to the 'images' collection
    await imagesCollection.add({
      'imageUrl': imageUrl,
      'userId': userId,
      'title': title,
      'likes': likes,
      'commentsCount':commentsCount,
      'likedBy': likedBy,
      'dateTime': dateTime,
      'profileImageUrl':profileImageUrl,
      'firstName':firstName,
      'status':status,
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
      int commentsCount=0;
      String uuid = AppStyles.uuid();
      DateTime now = DateTime.now();
      String dateTime= DateFormat('yyyy-MM-dd HH:mm').format(now);
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

              profileImageUrl= data['profileImageUrl'] ;
              firstName = data['firstName'];
            } else {
              print('Document data is null.');
            }

          }else{
            String message="user details not found";
            showAlert(context, message);
          }
          await addImageUrlToFirebase(user.uid,imageUrl, title!,likes,commentsCount,dateTime,likedBy,profileImageUrl,firstName,status);
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
    status=true;
    uploadImageAndSaveUrl();
  }
}

