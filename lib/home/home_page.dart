import 'dart:typed_data';

import 'package:facebook/home/show_user_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../basepage.dart';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;



class HomeScreen extends StatefulWidget {
   // Pass the user's email as a parameter
  final String email;

  const HomeScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Uint8List _image;
  final FirebaseStorage _storage=FirebaseStorage.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            color: Colors.blue,
            onPressed: () {
              print("hi");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShowUserDetailsPage(email: widget.email,),
                  ),
                );
            },
          ),
        ],
        flexibleSpace: Row(
          children: [
            IconButton(
              icon: Icon(Icons.facebook),
              color: Colors.blue, // Customize the color as needed
              onPressed: () {
                // Add your left-end icon onPressed functionality here.
              },
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
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
      body:
           Center(
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
                          'https://w7.pngwing.com/pngs/788/714/png-transparent-logo-facebook-social-media-business-restaurant-menu-books-blue-text-trademark.png'
                          ,width: 300,height: 200,),
                      ),
                    SizedBox(
                      width: 300,
                      child:TextButton( onPressed: uploadImageAndSaveUrl,child:Text("upload post")) ,),
                    SizedBox(width: 300,child: TextButton( onPressed: (){},child:Text("Text1")) ,),
                    SizedBox(width: 300,child: TextButton( onPressed: (){},child:Text("Text1")) ,),
                  ],
                ),
              ),
            ),
             Center(
                child: Container(

                  child: Column(
                    children: [
                      SizedBox(
                        width: 600,
                        child: Text("picture 1"),
                      ),
                      SizedBox(
                        width: 600,
                        child: Text("picture 2"),
                      ),
                      SizedBox(
                        width: 600,
                        child: Text("picture 3"),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> pickImageFromGallery() async {
    Uint8List img=await pickImage(ImageSource.gallery);
      _image=img;
      return _image;
  }

  void addImageUrlToFirebase(String userId, String imageUrl) {
    final databaseReference = FirebaseDatabase.instance.reference();
    print("inside add image url to firebase");

    databaseReference
        .child('users')
        .child(userId)
        .child('image_urls')
        .push()
        .set({'imageUrl': imageUrl});
  }
  void uploadImageAndSaveUrl() async {
    Uint8List imageFile = await pickImageFromGallery();

    if (imageFile != null) {
      String? imageUrl = await uploadImageToStorage('postImages',imageFile);
      if (imageUrl != null) {
        // Use the Firebase auth user's UID as the user ID
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print(user);
          addImageUrlToFirebase(user.uid, imageUrl);
          print('Image uploaded. URL: $imageUrl');
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
  Future<String> uploadImageToStorage(String childName,Uint8List file) async{
    print("inside upload image to storage");
    Reference ref= _storage.ref().child(childName);
    UploadTask uploadTask=ref.putData(file);
    TaskSnapshot snapshot=await uploadTask;
    String downloadUrl= await snapshot.ref.getDownloadURL();
    print("end of upload image to storage: downloadUrl is: $downloadUrl");
    return downloadUrl;
  }
}
