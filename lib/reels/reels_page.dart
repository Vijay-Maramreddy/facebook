import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facebook/reels/reels_collection_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chewie/chewie.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../app_style.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  XFile? _videoFile;
  String? _title;
  String? _videoDownloadURL;

  Future<XFile?> pickVideoFromGallery() async {
    XFile? videoFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    return videoFile;
  }

  Future<String?> uploadVideoToStorage(String childName, XFile videoFile) async {
    String uuid = AppStyles.uuid();
    final bytes = await videoFile.readAsBytes();
    FirebaseStorage storage = FirebaseStorage.instance;
    var videoFileName = '${DateTime.now()}.mp4';
    Reference child = storage.ref("Reelvideos").child(videoFileName);

    await child.putData(bytes);
    String downloadUrl = await child.getDownloadURL();
    return downloadUrl;
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
    _videoFile = await pickVideoFromGallery();

    if (_videoFile != null) {
      String uuid = AppStyles.uuid();
      DateTime now = DateTime.now();
      String dateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);
      String? videoUrl = await uploadVideoToStorage('videos/$uuid', _videoFile!);
      String? message = await _showVideoPickerDialog(videoUrl);

      final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('reels');
      User? user = FirebaseAuth.instance.currentUser;
      String? currentUserId = user?.uid;
      // String groupId = combineIds(currentUserId, widget.documentId);
      if (videoUrl != null) {
        await interactionsCollection.add({
          'createdBy': currentUserId,
          'videoUrl': videoUrl,
          'dateTime': dateTime,
          'message': message,
          'likes': 0,
          'likedBy': [],
          'sharesCount':0,
        });
      }
    } else {
      print('No video picked.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text("Reels Page"),
        ),
        body: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(10.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.lightBlueAccent,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.video_collection_outlined),
                color: Colors.black, // Customize the color as needed
                onPressed: () {
                  uploadVideoAndSaveUrl();
                },
              ),
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.all(10.0),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                width: 525,
                height: 545,
                child: SingleChildScrollView(
                  child: ReelsCollectionWidget(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
