import 'dart:html';
import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:facebook/Channels/group_info_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../Chat/all_interactions.dart';
import '../app_style.dart';
import '../base_page.dart';

class GroupChatWidget extends StatefulWidget {
  final String? clickedGroupId;
  final List<String> selectedGroupDocument;
  const GroupChatWidget({super.key, required this.clickedGroupId, required this.selectedGroupDocument});

  @override
  State<GroupChatWidget> createState() => _GroupChatWidgetState();
}

class _GroupChatWidgetState extends State<GroupChatWidget> {
  late String groupName='';
  late String groupDescription = '';
  late List<String> groupMembers = [];
  late String groupProfileImageUrl = '';

  TextEditingController _messageController = TextEditingController();
  Uint8List? image;
  XFile? video;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  VideoPlayerController? _videoPlayerController;
  bool isGroup=true;

  @override
  void initState() {
    setState(() {
      groupName = widget.selectedGroupDocument[0];
      groupProfileImageUrl = widget.selectedGroupDocument[1];
      getGroupData(widget.clickedGroupId!);

    });


    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupInfoPage(
                    groupId: widget.clickedGroupId,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(10.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.blue,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10.0),
              ),
              height: 60,
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
                        widget.selectedGroupDocument[1],
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Text(
                    widget.selectedGroupDocument[0] ?? '',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.vertical, // Change to vertical scroll
                child: Container(
                  height: 500,
                  child: Center(
                    child: AllInteractions(interactedBy: currentUserId, interactedWith: widget.clickedGroupId, groupId: widget.clickedGroupId,oppositeBlocked:const [],youBlocked:false),
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
                  height: 45,
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
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                        icon: Icon(Icons.emoji_emotions), // Emoji icon
                        onPressed: () {
                          openEmojiPicker(context); // Open the emoji picker modal bottom sheet
                        },
                      ),
                      IconButton(
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 6),
                        onPressed: uploadImageAndSaveUrl,
                        icon: Icon(Icons.add_a_photo),
                      ),
                      IconButton(
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                        onPressed: () async {
                          await uploadVideoAndSaveUrl();
                        },
                        icon: Icon(Icons.video_library),
                      )
                    ],
                  ),
                ),
                IconButton(
                    onPressed: () {
                      sendMessageOrIcon();
                    },
                    icon: Icon(Icons.send)),
                IconButton(
                  onPressed: () async {
                    await sendMessageWithLocation();
                  },
                  icon: Icon(Icons.map),
                ),
              ])
            ],
          ),
        ],
      ),
    );
  }

  Future<void> getGroupData(String clickedGroupId) async {
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
    await FirebaseFirestore.instance.collection('Groups').doc(clickedGroupId).get();

    if (documentSnapshot.exists) {
      setState(() {
        groupName = documentSnapshot.data()!['groupName'];
        groupDescription = documentSnapshot.data()!['description'];
        groupProfileImageUrl = documentSnapshot.data()!['groupProfileImageUrl'];
        groupMembers = List<String>.from(documentSnapshot.data()!['groupMembers'] as List<dynamic>);
      });
    } else {
      print("Group not found for id: $clickedGroupId");
    }
  }

  void openEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          children: [
            SizedBox(
              width: 500,
              height: 100,
              child: Row(
                children: [
                  Container(
                    width: 300,
                    height: 100,
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message....',
                      ),
                      onSubmitted: (String text) {
                        sendMessageOrIcon();
                        Navigator.pop(context); // Call your sendIcon function when the user submits the text (e.g., by pressing Enter)
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      sendMessageOrIcon();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    _messageController.text += emoji.emoji;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void sendMessageOrIcon() async {
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
        'interactedWith': widget.clickedGroupId,
        'imageUrl': imageUrl,
        'dateTime': formattedDateTime,
        'message': text,
        'groupId': widget.clickedGroupId,
        'videoUrl': '',
        'visibility':true,
      });
      _messageController.clear();
    setState(() {}); // Clear the text field after sending the message
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
  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<XFile?> pickVideoFromGallery() async {
    XFile? videoFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    return videoFile;
  }
  void uploadImageAndSaveUrl() async {
    image = await pickImageFromGallery();

    if (image != null) {
      String? message = await _showImagePickerDialog();
      String uuid = AppStyles.uuid();
      DateTime now = DateTime.now();
      String dateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);
      String? imageUrl = await uploadImageToStorage('groupImages/' + uuid, image!);
      final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
      User? user = FirebaseAuth.instance.currentUser;
      String? CurrentuserId = user?.uid;
      // String groupId = combineIds(CurrentuserId, widget.documentId);
      if (imageUrl != null) {
        await interactionsCollection.add({
          'interactedBy': CurrentuserId,
          'interactedWith': widget.clickedGroupId,
          'imageUrl': imageUrl,
          'dateTime': dateTime,
          'message': message,
          'groupId': widget.clickedGroupId,
          'videoUrl': '',
          'visibility':true,
        });
      }
    } else {
      print('No image picked.');
    }
  }

  Future<String?> _showVideoPickerDialog(String? videoUrl) async {
    if (videoUrl != null && videoUrl.isNotEmpty) {
      var message = '';

      final VideoPlayerController _videoPlayerController = VideoPlayerController.network(videoUrl);
      await _videoPlayerController.initialize();

      final ChewieController _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: true,
      );
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Send a Video'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display the video using ChewieController
                SizedBox(
                  width: 500,
                  height: 400,
                  child: Chewie(controller: _chewieController),
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

      // Dispose the controllers after the dialog is closed
      _videoPlayerController.dispose();
      _chewieController.dispose();

      return message;
    } else {
      return '';
    }
  }


  Future<void> uploadVideoAndSaveUrl() async {
    video = await pickVideoFromGallery();

    if (video != null) {
      String uuid = AppStyles.uuid();
      DateTime now = DateTime.now();
      String dateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);
      String? videoUrl = await uploadVideoToStorage('groupVideos/' + uuid, video!);
      String? message = await _showVideoPickerDialog(videoUrl);

      final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
      User? user = FirebaseAuth.instance.currentUser;
      String? currentUserId = user?.uid;
      // String groupId = combineIds(currentUserId, widget.documentId);
      if (videoUrl != null) {
        await interactionsCollection.add({
          'interactedBy': currentUserId,
          'interactedWith': widget.clickedGroupId,
          'videoUrl': videoUrl,
          'imageUrl': '',
          'dateTime': dateTime,
          'message': message,
          'groupId': widget.clickedGroupId,
          'visibility':true,
        });
      }
    } else {
      print('No video picked.');
    }
  }

  Future<String?> uploadVideoToStorage(String childName, XFile videoFile) async {
    String uuid = AppStyles.uuid();
    final bytes = await videoFile.readAsBytes();
    FirebaseStorage storage = FirebaseStorage.instance;
    var videoFileName = const Uuid().v4();
    Reference child = storage.ref("messagevideos").child(videoFileName);

    await child.putData(bytes);
    // TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await child.getDownloadURL();

    return downloadUrl;
  }

  Future<void> sendMessageWithLocation() async {
    String? locationMessage = await _getUserLocation();

    if (locationMessage != null) {
      // Send the location message to Firebase
      await sendMessage(locationMessage);
    } else {
      print('Unable to retrieve location.');
    }
  }
  Future<void> sendMessage(String message) async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    // String groupId = combineIds(currentUserId, widget.documentId);
    await interactionsCollection.add({
      'interactedBy': currentUserId,
      'interactedWith': widget.clickedGroupId,
      'imageUrl': '',
      'dateTime': formattedDateTime,
      'message': message,
      'groupId': widget.clickedGroupId,
      'videoUrl': '',
      'visibility':true,
    });
    // Clear the text field after sending the message
    _messageController.clear();
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

}


