import 'dart:collection';
import 'dart:html';
import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:facebook/Channels/group_info_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final List<dynamic> selectedGroupDocument;
  const GroupChatWidget({super.key, required this.clickedGroupId, required this.selectedGroupDocument});

  @override
  State<GroupChatWidget> createState() => _GroupChatWidgetState();
}

class _GroupChatWidgetState extends State<GroupChatWidget> {
  late String groupName='';
  late String groupDescription = '';
  late List<String> groupMembers = [];
  late String groupProfileImageUrl = '';
  String text="";
  String media="";

  final TextEditingController _messageController = TextEditingController();
  Uint8List? image;
  XFile? video;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool isGroup=true;
  Map<String,DateTime> seenBy={};

  @override
  void initState() {
    setState(() {
      groupName = widget.selectedGroupDocument[0];
      groupProfileImageUrl = widget.selectedGroupDocument[1];
      getGroupData(widget.clickedGroupId!);
      makeMessageCountZero();

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
          Row(
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
                  width: 900,
                  margin: const EdgeInsets.all(10.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  height: 60,
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
                        widget.selectedGroupDocument[0],
                        style: const TextStyle(fontSize: 20,),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
          Column(
            children: [
              SizedBox(
                height: 500,
                child: Center(
                  child: AllInteractions(interactedBy: currentUserId, interactedWith: widget.clickedGroupId, groupId: widget.clickedGroupId,oppositeBlocked:const [],youBlocked:false,string: text,media:media),
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
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Enter a message',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                        icon: const Icon(Icons.emoji_emotions), // Emoji icon
                        onPressed: () {
                          openEmojiPicker(context); // Open the emoji picker modal bottom sheet
                        },
                      ),
                      IconButton(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                        onPressed: uploadImageAndSaveUrl,
                        icon: const Icon(Icons.add_a_photo),
                      ),
                      IconButton(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                        onPressed: () async {
                          await uploadVideoAndSaveUrl();
                        },
                        icon: const Icon(Icons.video_library),
                      )
                    ],
                  ),
                ),
                IconButton(
                    onPressed: () {
                      sendMessageOrIcon();
                    },
                    icon: const Icon(Icons.send)),
                IconButton(
                  onPressed: () async {
                    await sendMessageWithLocation();
                  },
                  icon: const Icon(Icons.map),
                ),
                IconButton(
                  icon: const Icon(Icons.audio_file),
                  onPressed: () async {
                    await _pickaudio();
                  },
                )
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
        Map<String, dynamic> groupMembersMap = documentSnapshot.data()!['groupMembers'];
        groupMembers = groupMembersMap.keys.toList();

        // groupMembers =documentSnapshot.data()!['groupMembers'].keys.toList();

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
                  SizedBox(
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
    String? currentUserId = user?.uid;

    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    String? imageUrl = '';
    String text = _messageController.text;
    if (text.isNotEmpty) {
      await interactionsCollection.add({
        'seenStatus':false,
        'baseText':"",
        'interactedBy': currentUserId,
        'interactedWith': widget.clickedGroupId,
        'imageUrl': imageUrl,
        'dateTime': now,
        'message': text,
        'groupId': widget.clickedGroupId,
        'videoUrl': '',
        'audioUrl':'',
        'isVanish':false,
        'visibility':true,
        'seenBy':seenBy,
      });
      _messageController.clear();

      increaseMessageCount();

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
      String? imageUrl = await uploadImageToStorage('groupImages/$uuid', image!);
      final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
      User? user = FirebaseAuth.instance.currentUser;
      String? currentUserId = user?.uid;
      await interactionsCollection.add({
        'seenStatus':false,
        'baseText':"",
        'interactedBy': currentUserId,
        'interactedWith': widget.clickedGroupId,
        'imageUrl': imageUrl,
        'dateTime': now,
        'message': message,
        'groupId': widget.clickedGroupId,
        'videoUrl': '',
        'audioUrl':'',
        'isVanish':false,
        'visibility':true,
        'seenBy':seenBy,
      });
    } else {
      print('No image picked.');
    }
    increaseMessageCount();
  }

  Future<String?> _showVideoPickerDialog(String? videoUrl) async {
    if (videoUrl != null && videoUrl.isNotEmpty) {
      var message = '';

      final VideoPlayerController videoPlayerController = VideoPlayerController.network(videoUrl);
      await videoPlayerController.initialize();

      final ChewieController chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
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
                  child: Chewie(controller: chewieController),
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
      videoPlayerController.dispose();
      chewieController.dispose();

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
      String? videoUrl = await uploadVideoToStorage('groupVideos/$uuid', video!);
      String? message = await _showVideoPickerDialog(videoUrl);

      final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
      User? user = FirebaseAuth.instance.currentUser;
      String? currentUserId = user?.uid;
      // String groupId = combineIds(currentUserId, widget.documentId);
      if (videoUrl != null) {
        await interactionsCollection.add({
          'seenStatus':false,
          'baseText':"",
          'interactedBy': currentUserId,
          'interactedWith': widget.clickedGroupId,
          'videoUrl': videoUrl,
          'audioUrl':'',
          'imageUrl': '',
          'dateTime': now,
          'message': message,
          'groupId': widget.clickedGroupId,
          'isVanish':false,
          'visibility':true,
          'seenBy':seenBy,
        });
      }
    } else {
      print('No video picked.');
    }
    increaseMessageCount();
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
    await interactionsCollection.add({
      'seenStatus':false,
      'baseText':"",
      'interactedBy': currentUserId,
      'interactedWith': widget.clickedGroupId,
      'imageUrl': '',
      'dateTime': now,
      'message': message,
      'groupId': widget.clickedGroupId,
      'videoUrl': '',
      'audioUrl':'',
      'isVanish':false,
      'visibility':true,
      'seenBy':seenBy,
    });
    increaseMessageCount();
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

  Future<void> makeMessageCountZero() async {
    User? user=FirebaseAuth.instance.currentUser;
    String? currentUserId=user?.uid;
    try {
      CollectionReference groupsCollection = FirebaseFirestore.instance.collection('Groups');
      DocumentSnapshot groupDoc = await groupsCollection.doc(widget.clickedGroupId).get();

      if (groupDoc.exists) {
        Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
        LinkedHashMap<String, dynamic> linkedMap = groupData['messageCount'];
        Map<String, int> tempMessageCount = Map<String, int>.from(linkedMap);
        if (tempMessageCount.containsKey(currentUserId)) {
          tempMessageCount[currentUserId!] = 0;
        }
        // groupData['messageCount']=tempMessageCount;
        await groupsCollection.doc(widget.clickedGroupId).update({
          'messageCount': tempMessageCount,
        });
      } else {
        print('Document with groupId ${widget.clickedGroupId} does not exist.');
      }
    } catch (e) {
      print('Error updating messageCount: $e');
    }
  }

  Future<void> increaseMessageCount() async {
    User? user=FirebaseAuth.instance.currentUser;
    String? currentUserId=user?.uid;
    try {
      CollectionReference groupsCollection = FirebaseFirestore.instance.collection('Groups');
      DocumentSnapshot groupDoc = await groupsCollection.doc(widget.clickedGroupId).get();

      if (groupDoc.exists) {
        Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
        LinkedHashMap<String, dynamic> linkedMap = groupData['messageCount'];
        Map<String, int> tempMessageCount = Map<String, int>.from(linkedMap);
        tempMessageCount.forEach((key, value) {
          if (key != currentUserId) {
            tempMessageCount[key] = value + 1;
          }
        });
        // groupData['messageCount']=tempMessageCount;
        await groupsCollection.doc(widget.clickedGroupId).update({
          'messageCount': tempMessageCount,
        });
      } else {
        print('Document with groupId ${widget.clickedGroupId} does not exist.');
      }
    } catch (e) {
      print('Error updating messageCount: $e');
    }
  }

  Future<void> _pickaudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final PlatformFile audioFile = result.files.first;
      String audioUrl = await _uploadAudioToStorage(audioFile);
      addaudiotoFirestore(audioUrl);
    }
  }

  Future<String> _uploadAudioToStorage(PlatformFile audioFile) async {
    try {
      Reference audioRef = FirebaseStorage.instance.ref().child('audio').child(audioFile.name ?? 'audio_file.mp3');
      UploadTask uploadTask = audioRef.putData(audioFile.bytes!);

      await uploadTask.whenComplete(() => null);

      String audioUrl = await audioRef.getDownloadURL();

      return audioUrl;
    } catch (e) {
      print('Error uploading audio: $e');
      return '';
    }
  }

  Future<void> addaudiotoFirestore(String audioUrl) async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    DateTime now=DateTime.now();
    await interactionsCollection.add({
      'seenStatus': false,
      'baseText': "",
      'interactedBy': currentUserId,
      'interactedWith': widget.clickedGroupId,
      'videoUrl': "",
      'imageUrl': '',
      'dateTime': now,
      'message': "",
      'audioUrl':audioUrl,
      'isVanish':false,
      'groupId': widget.clickedGroupId,
      'visibility': true,
      'seenBy':seenBy,
    });
    increaseMessageCount();
  }


}








// const SizedBox(width: 10),
// ElevatedButton(
//     onPressed:(){
//       (media=="images")?(media=""):(media="images");
//       setState(() {
//         media;
//       });
//     },
//     child: Text("Show Images")
// ),
// const SizedBox(width: 10),
// ElevatedButton(
//     onPressed:(){
//       (media=="videos")?(media=""):(media="videos");
//       setState(() {
//         media;
//       });
//     },
//     child: Text("Show Videos")
// ),
// const SizedBox(width: 10),
// Expanded(
//   child: TextField(
//     onChanged: (value) {
//       setState(() {
//         text = value; // Update the string variable as text changes
//       });
//     },
//     decoration: InputDecoration(
//       hintText: 'Search...',
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//     ),
//   ),
// ),
