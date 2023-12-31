import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facebook/reels/video_container.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_style.dart';
import 'package:just_audio/just_audio.dart';

class BasePage extends StatelessWidget {
  const BasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

void showAlert(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Alert'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // Close the dialog
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

// Example usage:
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Alert Example'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              showAlert(context, 'This is a simple alert message.');
            },
            child: const Text('Show Alert'),
          ),
        ),
      ),
    );
  }
}

final BoxDecoration customBoxDecoration = BoxDecoration(
  border: Border.all(
    color: Colors.black,
  ),
  borderRadius: BorderRadius.circular(10),
  color: Colors.white,
);



pickImage(ImageSource source) async{
  final ImagePicker imagePicker =ImagePicker();
  XFile? file=await imagePicker.pickImage(source: source);
  if(file !=null){
    return await file.readAsBytes();
  }
  else{
    print("Image not found");
  }
}

Widget imagePicker(bool imageList, Function() onClick, String title1, String title2) {
  return GestureDetector(
      onTap: onClick,
      child: Container(
          height: imageList ? 50 : 100,
          decoration: BoxDecoration(color: const Color.fromARGB(255, 203, 231, 221), borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(vertical: AppStyles.appHorizontalPadding / 2),
          padding: const EdgeInsets.all(AppStyles.appHorizontalPadding),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!imageList) ...[
                Icon(
                  Icons.camera_alt,
                  size: imageList ? 4 : 12,
                  color: Colors.orange,
                )
              ],
              Text(
                imageList ? title1 : title2,
                style: const TextStyle(color: Colors.black38),
              )
            ],
          )));
}

String combineIds(String? currentuserId, String? documentId) {
  List<String> sortedStrings = sortStrings(currentuserId!, documentId!);
  String str1=sortedStrings[0];
  String str2=sortedStrings[1];
  String groupId='$str1-$str2';
  return groupId;
}

List<String> sortStrings(String str1, String str2) {
  List<String> stringsList = [str1, str2];
  stringsList.sort(); // Sort the list lexicographically

  return stringsList;
}

class UserProfileDetails {
  final String? profileImageUrl;
  final String? firstName;

  UserProfileDetails({this.profileImageUrl, this.firstName});
}

Future<UserProfileDetails> getProfileDetails(String userId) async {
  try {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

    if (data != null) {
      String? profileImageUrl = data['profileImageUrl'] as String?;
      String? firstName = data['firstName'] as String?;
      return UserProfileDetails(profileImageUrl: profileImageUrl, firstName: firstName);
    } else {
      return UserProfileDetails(profileImageUrl: null, firstName: null);
    }
  } catch (e) {
    print('Error getting profile details: $e');
    return UserProfileDetails(profileImageUrl: null, firstName: null);
  }
}


void shareOnWhatsApp(String link) async {
  final url = 'https://api.whatsapp.com/send?text=Check%20out%20this%20reel:%20$link';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

void shareOnFacebook(String link) async {
  final url = 'https://www.facebook.com/sharer/sharer.php?u=Check%20out%20this%20reel:%20$link';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

void shareOnTelegram(String link) async {
  final url = 'https://t.me/share/url?url=Check%20out%20this%20reel:%20$link';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}



class AudioMessageWidget extends StatefulWidget {
  final String audioUrl;
  final AudioPlayer audioPlayer; // Pass the AudioPlayer instance from the parent

  const AudioMessageWidget({super.key, required this.audioUrl, required this.audioPlayer});

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  bool isPlaying = false;
  Duration audioDuration = const Duration(seconds: 0);
  Duration audioPosition = const Duration(seconds: 0);

  @override
  void initState() {
    super.initState();
    widget.audioPlayer.setUrl(widget.audioUrl);
    widget.audioPlayer.playerStateStream.listen((PlayerState state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          isPlaying = false;
        });
      }
    });

    widget.audioPlayer.positionStream.listen((Duration? position) {
      if (position != null) {
        setState(() {
          audioPosition = position;
        });
      }
    });

    widget.audioPlayer.durationStream.listen((Duration? duration) {
      if (duration != null) {
        if(mounted) {
          setState(() {
            audioDuration = duration;
          });
        }
      }
    });
  }

  Future<void> _playAudio() async {
    if (widget.audioPlayer.playing) {
      await widget.audioPlayer.pause();
    } else {
      await widget.audioPlayer.play();
    }
    if(mounted) {
      setState(() {
        isPlaying = widget.audioPlayer.playing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = audioDuration.inMilliseconds > 0
        ? audioPosition.inMilliseconds / audioDuration.inMilliseconds
        : 0.0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(

          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(width:2),
            color: Colors.white60,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: isPlaying ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
                onPressed: () {
                  _playAudio();
                  if(mounted) {
                    setState(() {
                      isPlaying = widget.audioPlayer.playing;
                    });
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: SizedBox(
                  width: 350,
                  child: LinearProgressIndicator(
                    value: progress,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    backgroundColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget buildVideoUrl(String urlString, Map<String, dynamic> data) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Text(data['message'], style: const TextStyle(fontSize: 24, color: Colors.black87, fontWeight: FontWeight.w400)),
      ),
      Container(
        width: 400,
        height: 260,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: VideoContainer(
          videoUrl: urlString,
        ),
      ),
    ],
  );
}

Widget buildMessageUrl(String message) {
  return Visibility(
    visible: message.startsWith('https://'),
    child: Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              window.open(message, '_blank');
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                message,
                style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildMessage(String message) {
  return Column(
    children: [
      Container(
        width: 400,
        color: Colors.white60,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          children: [
            ExpandableMessageWidget(message:message, maxLines: 2),
          ],
        ),
      ),
    ],
  );
}

Widget buildImage(String imageUrl, String message) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Text(message, style: const TextStyle(fontSize: 24, color: Colors.black87, fontWeight: FontWeight.w400)),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Image.network(
          imageUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      ),
    ],
  );
}

class ExpandableMessageWidget extends StatefulWidget {
  final String message;
  final int maxLines;

  ExpandableMessageWidget({required this.message, this.maxLines = 2});

  @override
  _ExpandableMessageWidgetState createState() => _ExpandableMessageWidgetState();
}

class _ExpandableMessageWidgetState extends State<ExpandableMessageWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 400,
          color: Colors.white60,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
              Text(
                widget.message,
                style: const TextStyle(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.w400),
                maxLines: isExpanded ? null : widget.maxLines,
                overflow: isExpanded ? null : TextOverflow.ellipsis,
              ),
              if (!isExpanded && widget.message.length > widget.maxLines * 40) // Adjust 40 based on your font size and preferences
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded = true;
                    });
                  },
                  child: Text(
                    'Show More',
                    style: const TextStyle(fontSize: 20, color: Colors.blue),
                  ),
                ),
              if (isExpanded)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded = false;
                    });
                  },
                  child: Text(
                    'Show Less',
                    style: const TextStyle(fontSize: 20, color: Colors.blue),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

