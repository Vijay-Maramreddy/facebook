
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facebook/home/show_user_details_page.dart';
import 'package:facebook/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../AppAtyle.dart';
import '../Posts/ImageCollectionWidget.dart';
import '../basepage.dart';

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
              icon: const Icon(Icons.facebook),
              color: Colors.blue, // Customize the color as needed
              onPressed: () {
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
      body: Center(
        child: Row(
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
                        width: 300,
                        height: 200,
                      ),
                    ),
                    SizedBox(
                      width: 300,
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
                      width: 300,
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
                      width: 300,
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
            Center(
              child: ImageCollectionWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
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

  Future<void> addImageUrlToFirebase(String userId, String imageUrl, String title, int likes, List<String> comments, List<String> likedBy) async {
    final CollectionReference imagesCollection = FirebaseFirestore.instance.collection('images');

    // Add a new document to the 'images' collection
    await imagesCollection.add({
      'imageUrl': imageUrl,
      'userId': userId,
      'title': title,
      'likes': likes,
      'likedBy': likedBy,
      'comments': comments,
    });

    // Insert the new image data at the beginning of the list
    // imageDataList.insert(
    //   0,
    //   ImageData(
    //     imageUrl: imageUrl,
    //     likes: likes,
    //     comments: comments,
    //     isLiked: false,
    //     isCommentVisible: false,
    //   ),
    // );
  }

  void uploadImageAndSaveUrl() async {
    imageFile = await pickImageFromGallery();

    if (imageFile != null) {
      String? title = await _showImagePickerDialog();
      int likes = 0;
      List<String> comments = [];
      List<String> likedBy = [];
      // String? title = await _showImagePickerDialog();
      print("hi $title");
      String uuid = AppStyles.uuid();

      String? imageUrl = await uploadImageToStorage('postImages/' + uuid, imageFile);
      if (imageUrl != null) {
        // Use the Firebase auth user's UID as the user ID
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print(user.uid);
          print(title);
          await addImageUrlToFirebase(user.uid, imageUrl, title!, likes, comments, likedBy);
          print('Image uploaded. URL: $imageUrl');
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
    print("inside upload image to storage");
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    print("end of upload image to storage: downloadUrl is: $downloadUrl");
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
                  // Do something with the picked image and title
                  // For demonstration, we'll just print the title
                  print('Title: $title');

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
}
