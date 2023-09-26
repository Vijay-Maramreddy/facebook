import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../app_style.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';
import 'all_interactions.dart';

class ChatWidget extends StatefulWidget {
  final Map<String, dynamic>? documentData;
  final String? documentId;
  ChatWidget({this.documentData, this.documentId});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  TextEditingController _messageController = TextEditingController();
  Uint8List? image;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Map<String, dynamic>? documentData;

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String? CurrentuserId = user?.uid;
    print(widget.documentId);
    getDocumentById(widget.documentId);
    if (documentData == null) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: 1000,
          height: 600,
          child: Scaffold(
            body: Text("select a friend"),
          ),
        ),
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: 1000,
          height: 600,
          child: Scaffold(
            body: Container(
              child: Column(children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowUserDetailsPage(
                          userId: widget.documentId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.blue,
                    height: 40,
                    // width: 1400,
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
                              documentData!['profileImageUrl'] ?? '',
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Text(
                          documentData!['firstName'] ?? '',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.vertical, // Change to vertical scroll
                  child: Container(
                    height: 500,
                    child: Center(
                      child:AllInteractions(interactedBy:CurrentuserId,interactedWith:widget.documentId),
                    ),
                  ),
                ),
                Row(children: [
                  Container(
                    decoration: customBoxDecoration,
                    margin: const EdgeInsets.all(10),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    width: 700,
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Enter a message',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: uploadImageAndSaveUrl,
                          icon: Icon(Icons.add_a_photo),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () async {
                        User? user = FirebaseAuth.instance.currentUser;
                        String? CurrentuserId = user?.uid;
                        DateTime now = DateTime.now();
                        String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

                        final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
                        String? imageUrl = '';
                        String text = _messageController.text;
                        if (text.isNotEmpty) {
                          await interactionsCollection.add({
                            'interactedBy': CurrentuserId,
                            'interactedWith': widget.documentId,
                            'imageUrl': imageUrl,
                            'dateTime': formattedDateTime,
                            'message': text,
                          });
                          _messageController.clear(); // Clear the text field after sending the message
                        }
                      },
                      icon: Icon(Icons.send)),
                ])
              ]),
            ),
          ),
        ),
      );
    }
  }

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> getDocumentById(String? documentId) async {
    try {
      CollectionReference collection = FirebaseFirestore.instance.collection('users');

      DocumentSnapshot documentSnapshot = await collection.doc(documentId).get();

      if (documentSnapshot.exists) {
        documentData = documentSnapshot.data() as Map<String, dynamic>;
      } else {
        print('No such document with ID: $documentId');
      }
    } catch (e) {
      print('Error retrieving document: $e');
    }
  }

  void uploadImageAndSaveUrl() async {
    image = await pickImageFromGallery();

    if (image != null) {
      String? message = await _showImagePickerDialog();
      String uuid = AppStyles.uuid();
      DateTime now = DateTime.now();
      String dateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);
      String? imageUrl = await uploadImageToStorage('postImages/' + uuid, image!);
      final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
      User? user = FirebaseAuth.instance.currentUser;
      String? CurrentuserId = user?.uid;
      if (imageUrl != null) {
        await interactionsCollection.add({
          'interactedBy': CurrentuserId,
          'interactedWith': widget.documentId,
          'imageUrl': imageUrl,
          'dateTime': dateTime,
          'message': message,
        });
      }
    } else {
      print('No image picked.');
    }
  }

  Future<Uint8List?> pickImageFromGallery() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    image = img;
    return image;
  }

  Future<String?> _showImagePickerDialog() async {
    if (image != null) {
      var message = '';
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Send a Image'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(image!),
                TextField(
                  onChanged: (value) {
                    message = value;
                  },
                  decoration: const InputDecoration(labelText: 'type a message'),
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
                  Navigator.pop(context, message);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      return message;
    } else {
      return '';
    }
  }
}

