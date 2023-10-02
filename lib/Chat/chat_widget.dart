import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../app_style.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';
import 'all_interactions.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:html';
// import 'dart:io';


class ChatWidget extends StatefulWidget {
  final Map<String, dynamic>? documentData;
  final String? documentId;
  final String? groupId;
  ChatWidget({super.key, this.documentData, this.documentId, this.groupId});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  TextEditingController _messageController = TextEditingController();
  Uint8List? image;
  XFile? video;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  VideoPlayerController? _videoPlayerController;

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String? CurrentuserId = user?.uid;
    print(widget.documentId);
    if (widget.documentData == null) {
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
                        builder: (context) =>
                            ShowUserDetailsPage(
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
                              widget.documentData!['profileImageUrl'] ?? '',
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Text(
                          widget.documentData!['firstName'] ?? '',
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
                      child: AllInteractions(interactedBy: CurrentuserId, interactedWith: widget.documentId, groupId: widget.groupId),
                    ),
                  ),
                ),
                Row(children: [
                  Container(
                    decoration: customBoxDecoration,
                    margin: const EdgeInsets.all(10),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    width: 850,
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
                        IconButton(onPressed: () async {
                          print("Button is pressed");
                          await uploadVideoAndSaveUrl();
                        },
                          icon: Icon(Icons.video_library),
                        )
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
                        String groupId = combineIds(CurrentuserId, widget.documentId);
                        if (text.isNotEmpty) {
                          await interactionsCollection.add({
                            'interactedBy': CurrentuserId,
                            'interactedWith': widget.documentId,
                            'imageUrl': imageUrl,
                            'dateTime': formattedDateTime,
                            'message': text,
                            'groupId': groupId,
                          });
                          _messageController.clear();
                          // setState(() {}); // Clear the text field after sending the message
                        }
                      },
                      icon: Icon(Icons.send)),
                  IconButton(
                    onPressed: () async {
                      print("button is pressed");
                      await sendMessageWithLocation();
                    },
                    icon: Icon(Icons.map),
                  ),
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
      String groupId = combineIds(CurrentuserId, widget.documentId);
      if (imageUrl != null) {
        await interactionsCollection.add({
          'interactedBy': CurrentuserId,
          'interactedWith': widget.documentId,
          'imageUrl': imageUrl,
          'dateTime': dateTime,
          'message': message,
          'groupId': groupId,
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


  Future<void> sendMessageWithLocation() async {
    String? locationMessage = await _getUserLocation();
    print("$locationMessage");

    if (locationMessage != null) {
      // Send the location message to Firebase
      await sendMessage(locationMessage);
    } else {
      print('Unable to retrieve location.');
    }
  }

  Future<String?> _getUserLocation() async {
    try {
      final Geoposition geoposition = await window.navigator.geolocation.getCurrentPosition();
      final Coordinates? coords = geoposition.coords;
      num? latitude = coords?.latitude!;
      num? longitude = coords?.longitude!;
      return 'https://www.google.com/maps/place/$latitude,$longitude';
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<void> sendMessage(String message) async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    String groupId = combineIds(currentUserId, widget.documentId);
    await interactionsCollection.add({
      'interactedBy': currentUserId,
      'interactedWith': widget.documentId,
      'imageUrl': '',
      'dateTime': formattedDateTime,
      'message': message,
      'groupId': groupId,
    });
    // Clear the text field after sending the message
    _messageController.clear();
  }

  Future<String?> _showVideoPickerDialog() async {
    if (video != null) {
      print("inside video dialog box");
      var message = '';
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Send a Video'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display a thumbnail or preview of the video if available
                // You can use a VideoPlayer widget for this
                SizedBox(
                  width: 200,
                  height: 200,
                  child: VideoPlayer(video! as VideoPlayerController),
                ),
                TextField(
                  onChanged: (value) {
                    message = value;
                  },
                  decoration: const InputDecoration(labelText: 'Type a message'),
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

  Future<XFile?> pickVideoFromGallery() async {
    XFile? videoFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    print(videoFile);
    return videoFile;
  }

  Future<void> uploadVideoAndSaveUrl() async {
    video = await pickVideoFromGallery();

    if (video != null) {
      String? message = await _showVideoPickerDialog();
      String uuid = AppStyles.uuid();
      DateTime now = DateTime.now();
      String dateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);
      String? videoUrl = await uploadVideoToStorage('videos/' + uuid, video!);

      final CollectionReference interactionsCollection =
      FirebaseFirestore.instance.collection('interactions');
      User? user = FirebaseAuth.instance.currentUser;
      String? currentUserId = user?.uid;
      String groupId = combineIds(currentUserId, widget.documentId);
      if (videoUrl != null) {
        await interactionsCollection.add({
          'interactedBy': currentUserId,
          'interactedWith': widget.documentId,
          'videoUrl': videoUrl,
          'imageUrl': '',
          'dateTime': dateTime,
          'message': message,
          'groupId': groupId,
        });
      }
    } else {
      print('No video picked.');
    }
  }


  Future<String?> uploadVideoToStorage(String childName, XFile videoFile) async {
    String uuid = AppStyles.uuid();
    // String videoFileName = '$childName/$uuid.mp4';
    //
    // // Create a File object using dart:io's File class
    // File file = File(videoFile.path!);
    //
    // Reference ref = _storage.ref().child(videoFileName);
    // UploadTask uploadTask = ref.putFile(file);
    // TaskSnapshot snapshot = await uploadTask;
    // String downloadUrl = await snapshot.ref.getDownloadURL();
    final bytes = await videoFile.readAsBytes();
    FirebaseStorage storage = FirebaseStorage.instance;
    // var videoFileName = const Uuid().v4();
    Reference child = storage.ref("messagevideos").child(uuid);

    await child.putData(bytes);
    // TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await child.getDownloadURL();

    return downloadUrl;
  }}