import 'dart:async';
import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../app_style.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';
import 'all_interactions.dart';
import 'dart:html';
import 'package:file_picker/file_picker.dart';

class ChatWidget extends StatefulWidget {
  final Map<String, dynamic>? selectedUserDetailsDocumentData;
  final String? selectedUserDetailsDocumentId;
  final String? groupId;
  final bool? isBlockedByYou;
  const ChatWidget(BuildContext context, {
    super.key,
    this.selectedUserDetailsDocumentData,
    this.selectedUserDetailsDocumentId,
    this.groupId,
    required this.isBlockedByYou,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  Uint8List? image;
  XFile? video;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String text = "";
  String media = "";
  String audioLink = "";
  bool? _isSwitched = false;
  Map<String, DateTime> seenBy = {};
  late String callBackDocumentId = "";
  late bool isReply = false;

  late int count;
  late final bool _isBlockedByYou = widget.isBlockedByYou!;
  late List<String> oppositeBlocked = [];
  late String callBackMessage = "";
  late DocumentSnapshot? callBackSnapshot = null;
  final AudioPlayer audioPlayer = AudioPlayer();
  String currentUserId = "";
  late bool isVanish = false;
  final CollectionReference messageCount = FirebaseFirestore.instance.collection('messageCount');
  late DocumentReference documentReference;
  late String documentId = "";
  late String status = "";
  late StreamSubscription<DocumentSnapshot> _listenerSubscription;

  @override
  void initState() {
    User? user = FirebaseAuth.instance.currentUser;
    currentUserId = user!.uid;
    setStatus();

    fetchDocumentId();

    setState(() {
      currentUserId;
    });
    updateMessageSeenStatus(false);
    super.initState();
    getIsVanish();
  }

  @override
  Widget build(BuildContext context) {
    getIsVanish();
    updateMessageSeenStatus(false);
    _isSwitched = isVanish;
    getOppositeBlockList();
    if (widget.selectedUserDetailsDocumentData == null) {
      return const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
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
        child: SizedBox(
          width: 1000,
          height: 650,
          child: Scaffold(
            body: Column(children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowUserDetailsPage(
                            userId: widget.selectedUserDetailsDocumentId,
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
                      width: 350,
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
                                widget.selectedUserDetailsDocumentData!['profileImageUrl'] ?? '',
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
                            widget.selectedUserDetailsDocumentData!['firstName'] ?? '',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(status != '' ? "Active Now" : "Not Active"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                      onPressed: () {
                        (media == "images") ? (media = "") : (media = "images");
                        setState(() {
                          media;
                        });
                      },
                      child: const Text("Show Images")),
                  const SizedBox(width: 10),
                  ElevatedButton(
                      onPressed: () {
                        (media == "videos") ? (media = "") : (media = "videos");
                        setState(() {
                          media;
                        });
                      },
                      child: const Text("Show Videos")),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          text = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Switch(
                        value: _isSwitched!,
                        onChanged: (value) async {
                          _isSwitched = value;
                          await changeVanishState(_isSwitched);
                          setState(() {
                            _isSwitched;
                            isVanish = _isSwitched!;
                          });
                        },
                      ),
                      Text('Disappearing mode Switched $_isSwitched'),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  SizedBox(
                    height: 410,
                    child: Center(
                      child: AllInteractions(this.context,
                        interactedBy: currentUserId,
                        interactedWith: widget.selectedUserDetailsDocumentId,
                        groupId: widget.groupId,
                        oppositeBlocked: oppositeBlocked,
                        youBlocked: _isBlockedByYou,
                        string: text,
                        media: media,
                        updateState: updateState,
                      ),
                    ),
                  ),
                  if (callBackSnapshot != null)
                    Container(
                      height: 80,
                      margin: const EdgeInsets.all(2.0),
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: Colors.white60,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      child: SingleChildScrollView(
                        child: Row(
                          children: [
                            if (callBackSnapshot?['audioUrl'] != "")
                              AudioMessageWidget(audioUrl: callBackSnapshot?['audioUrl'], audioPlayer: audioPlayer)
                            else if (callBackSnapshot?['videoUrl'] != "" && callBackSnapshot?['videoUrl'] != null)
                              SizedBox(
                                child: Text(callBackSnapshot?['message']),
                                // child: buildVideoUrl(callBackSnapshot?['videoUrl'], callBackSnapshot as Map<String, dynamic>),
                              )
                            else if (callBackSnapshot?['imageUrl'] == "" && callBackSnapshot?['videoUrl'] == "")
                              if (callBackSnapshot?['message']!.startsWith('https://'))
                                SizedBox(
                                  child: buildMessageUrl(callBackSnapshot?['message']),
                                )
                              else
                                SizedBox(
                                  child: buildMessage(callBackSnapshot?['message']),
                                )
                            else
                              SizedBox(
                                child: buildImage(callBackSnapshot?['imageUrl'], callBackSnapshot?['message']),
                              ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  callBackDocumentId = "";
                                  callBackSnapshot = null;
                                });
                              },
                              icon: const Icon(Icons.cancel),
                            )
                          ],
                        ),
                      ),
                    ),
                  Visibility(
                    visible: (!_isBlockedByYou) && (!oppositeBlocked.contains(currentUserId)),
                    child: Row(children: [
                      Container(
                        decoration: customBoxDecoration,
                        margin: const EdgeInsets.all(10),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        width: 700,
                        // height: 45,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                autofocus: true,
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter a message',
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (text) {
                                  sendMessageOrIcon();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            sendMessageOrIcon();
                          },
                          icon: const Icon(Icons.send)),
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
                      ),
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
                    ]),
                  )
                ],
              ),
            ]),
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
      String? imageUrl = await uploadImageToStorage('postImages/$uuid', image!);
      final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
      String groupId = combineIds(currentUserId, widget.selectedUserDetailsDocumentId);
      await interactionsCollection.add({
        'seenStatus': false,
        'baseText': "",
        'interactedBy': currentUserId,
        'interactedWith': widget.selectedUserDetailsDocumentId,
        'imageUrl': imageUrl,
        'dateTime': now,
        'message': message,
        'groupId': groupId,
        'videoUrl': '',
        'audioUrl': '',
        'visibility': !_isBlockedByYou,
        'seenBy': seenBy,
        'isVanish': _isSwitched,
        'replyTo': callBackDocumentId,
      });
      setState(() {
        callBackSnapshot = null;
        callBackDocumentId = "";
      });
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

    if (locationMessage != null) {
      // Send the location message to Firebase
      await sendMessage(locationMessage);
      setState(() {
        callBackSnapshot = null;
        callBackDocumentId = "";
      });
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
    DateTime now = DateTime.now();
    // String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    String groupId = combineIds(currentUserId, widget.selectedUserDetailsDocumentId);
    await interactionsCollection.add({
      'seenStatus': false,
      'baseText': "",
      'interactedBy': currentUserId,
      'interactedWith': widget.selectedUserDetailsDocumentId,
      'imageUrl': '',
      'dateTime': now,
      'message': message,
      'groupId': groupId,
      'videoUrl': '',
      'audioUrl': '',
      'isVanish': _isSwitched,
      'visibility': !_isBlockedByYou,
      'seenBy': seenBy,
      'replyTo': callBackDocumentId,
    });
    // Clear the text field after sending the message
    _messageController.clear();
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

      videoPlayerController.dispose();
      chewieController.dispose();

      return message;
    } else {
      return '';
    }
  }

  Future<XFile?> pickVideoFromGallery() async {
    XFile? videoFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    return videoFile;
  }

  Future<void> uploadVideoAndSaveUrl() async {
    video = await pickVideoFromGallery();

    if (video != null) {
      String uuid = AppStyles.uuid();
      DateTime now = DateTime.now();
      String? videoUrl = await uploadVideoToStorage('videos/$uuid', video!);
      String? message = await _showVideoPickerDialog(videoUrl);

      final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
      String groupId = combineIds(currentUserId, widget.selectedUserDetailsDocumentId);
      if (videoUrl != null) {
        await interactionsCollection.add({
          'seenStatus': false,
          'baseText': "",
          'interactedBy': currentUserId,
          'interactedWith': widget.selectedUserDetailsDocumentId,
          'videoUrl': videoUrl,
          'audioUrl': '',
          'imageUrl': '',
          'dateTime': now,
          'message': message,
          'isVanish': _isSwitched,
          'groupId': groupId,
          'visibility': !_isBlockedByYou,
          'seenBy': seenBy,
          'replyTo': callBackDocumentId,
        });
      }
      setState(() {
        callBackSnapshot = null;
        callBackDocumentId = "";
      });
    } else {
      print('No video picked.');
    }
  }

  Future<String?> uploadVideoToStorage(String childName, XFile videoFile) async {
    final bytes = await videoFile.readAsBytes();
    FirebaseStorage storage = FirebaseStorage.instance;
    var videoFileName = const Uuid().v4();
    Reference child = storage.ref("messagevideos").child(videoFileName);

    await child.putData(bytes);
    String downloadUrl = await child.getDownloadURL();
    return downloadUrl;
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
                  if (mounted) {
                    setState(() {
                      _messageController.text += emoji.emoji;
                    });
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void sendMessageOrIcon() async {
    CollectionReference messageCount = FirebaseFirestore.instance.collection('messageCount');

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await messageCount
        .where('interactedBy', isEqualTo: currentUserId)
        .where('interactedTo', isEqualTo: widget.selectedUserDetailsDocumentId)
        .get() as QuerySnapshot<Map<String, dynamic>>;
    DocumentSnapshot<Map<String, dynamic>> doc = querySnapshot.docs.first;
    count = doc['count'];
    count = count + 1;
    await doc.reference.update({'count': count});

    DateTime now = DateTime.now();

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    String? imageUrl = '';
    String text = _messageController.text;
    String groupId = combineIds(currentUserId, widget.selectedUserDetailsDocumentId);
    if (text.isNotEmpty) {
      await interactionsCollection.add({
        'seenStatus': false,
        'baseText': "",
        'interactedBy': currentUserId,
        'interactedWith': widget.selectedUserDetailsDocumentId,
        'imageUrl': imageUrl,
        'dateTime': now,
        'message': text,
        'groupId': groupId,
        'videoUrl': '',
        'audioUrl': '',
        'isVanish': _isSwitched,
        'visibility': !_isBlockedByYou,
        'seenBy': seenBy,
        'replyTo': callBackDocumentId,
      });
      _messageController.clear();
    }
    setState(() {
      callBackSnapshot = null;
      callBackDocumentId = "";
    });
  }

  Future<void> getOppositeBlockList() async {
    DocumentReference documentReference = FirebaseFirestore.instance.collection('users').doc(widget.selectedUserDetailsDocumentId);
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await documentReference.get() as DocumentSnapshot<Map<String, dynamic>>;
    if (documentSnapshot.data() != null) {
      List<String> blockedData = List<String>.from(documentSnapshot.data()!['blocked']);

      oppositeBlocked = List<String>.from(blockedData);
    } else {
      print("document snapshot of opposite user is empty");
    }
  }

  Future<void> updateMessageSeenStatus(bool bool) async {
    CollectionReference interactions = FirebaseFirestore.instance.collection('interactions');
    String? userIs = currentUserId;
    if (bool == true) {
      userIs = widget.selectedUserDetailsDocumentId;
    }
    QuerySnapshot querySnapshot1 = await interactions
        .where('groupId', isEqualTo: widget.groupId)
        .where('interactedBy', isEqualTo: userIs)
        .where('isVanish', isEqualTo: true)
        .where('seenStatus', isEqualTo: true)
        .get();
    for (QueryDocumentSnapshot doc in querySnapshot1.docs) {
      await doc.reference.delete();
      print('Document deleted: ${doc.id}');
    }

    QuerySnapshot querySnapshot =
        await interactions.where('groupId', isEqualTo: widget.groupId).where('interactedWith', isEqualTo: currentUserId).get();

    for (QueryDocumentSnapshot document in querySnapshot.docs) {
      interactions.doc(document.id).update({
        'seenStatus': true,
      }).then((_) {
        print('Document ${document.id} updated successfully.');
      }).catchError((error) {
        print('Error updating document: $error');
      });
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
      addAudioToFireStore(audioUrl);
    }
  }

  Future<String> _uploadAudioToStorage(PlatformFile audioFile) async {
    try {
      Reference audioRef = FirebaseStorage.instance.ref().child('audio').child(audioFile.name);
      UploadTask uploadTask = audioRef.putData(audioFile.bytes!);

      await uploadTask.whenComplete(() => null);

      String audioUrl = await audioRef.getDownloadURL();

      return audioUrl;
    } catch (e) {
      print('Error uploading audio: $e');
      return '';
    }
  }

  Future<void> addAudioToFireStore(String audioUrl) async {
    CollectionReference messageCount = FirebaseFirestore.instance.collection('messageCount');

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await messageCount
        .where('interactedBy', isEqualTo: currentUserId)
        .where('interactedTo', isEqualTo: widget.selectedUserDetailsDocumentId)
        .get() as QuerySnapshot<Map<String, dynamic>>;
    DocumentSnapshot<Map<String, dynamic>> doc = querySnapshot.docs.first;
    count = doc['count'];
    count = count + 1;
    await doc.reference.update({'count': count});
    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    DateTime now = DateTime.now();
    String groupId = combineIds(currentUserId, widget.selectedUserDetailsDocumentId);
    await interactionsCollection.add({
      'seenStatus': false,
      'baseText': "",
      'interactedBy': currentUserId,
      'interactedWith': widget.selectedUserDetailsDocumentId,
      'videoUrl': "",
      'imageUrl': '',
      'dateTime': now,
      'message': "",
      'audioUrl': audioUrl,
      'groupId': groupId,
      'isVanish': _isSwitched,
      'visibility': !_isBlockedByYou,
      'seenBy': seenBy,
      'replyTo': callBackDocumentId,
    });
    setState(() {
      callBackSnapshot = null;
      callBackDocumentId = "";
    });
  }

  Future<void> changeVanishState(bool? isSwitched) async {
    CollectionReference messageCount = FirebaseFirestore.instance.collection('messageCount');

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await messageCount
        .where('interactedBy', isEqualTo: currentUserId)
        .where('interactedTo', isEqualTo: widget.selectedUserDetailsDocumentId)
        .get() as QuerySnapshot<Map<String, dynamic>>;
    DocumentSnapshot<Map<String, dynamic>> doc = querySnapshot.docs.first;
    String documentId = doc.id;
    await messageCount.doc(documentId).update({
      'isVanish': _isSwitched,
    });

    QuerySnapshot<Map<String, dynamic>> querySnapshot2 = await messageCount
        .where('interactedBy', isEqualTo: widget.selectedUserDetailsDocumentId)
        .where('interactedTo', isEqualTo: currentUserId)
        .get() as QuerySnapshot<Map<String, dynamic>>;
    DocumentSnapshot<Map<String, dynamic>> doc2 = querySnapshot2.docs.first;
    await doc2.reference.update({'isVanish': _isSwitched});
  }

  void updateState(String documentId) {
    callBackDocumentId = documentId;
    fetchCallBackDocument();
    setState(() {
      callBackDocumentId;
      isReply = true;
    });
  }

  void obtainIsVanish() {
    _isSwitched = isVanish;
    setState(() {
      _isSwitched;
    });
  }

  Future<void> fetchCallBackDocument() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('interactions').doc(callBackDocumentId).get();
    callBackSnapshot = snapshot;
    String tempVideoUrl = callBackSnapshot?['videoUrl'];
    if (tempVideoUrl != "") {
      print("the video url is :$tempVideoUrl");
    }
    setState(() {
      callBackSnapshot;
    });
  }

  Future<void> getIsVanish() async {
    CollectionReference messageCount = FirebaseFirestore.instance.collection('messageCount');

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await messageCount
        .where('interactedBy', isEqualTo: currentUserId)
        .where('interactedTo', isEqualTo: widget.selectedUserDetailsDocumentId)
        .get() as QuerySnapshot<Map<String, dynamic>>;
    DocumentSnapshot<Map<String, dynamic>> doc = querySnapshot.docs.first;
    isVanish = doc['isVanish'];
  }

  Future<void> fetchDocumentId() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('messageCount')
        .where('interactedBy', isEqualTo: currentUserId)
        .where('interactedTo', isEqualTo: widget.selectedUserDetailsDocumentId)
        .get();
    documentId = querySnapshot.docs[0].id;
    print("the documentId is $documentId");
    documentReference = messageCount.doc(documentId);
    _listenerSubscription = documentReference.snapshots().listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          status = data['status'] ?? '';
        });
      } else {
        setState(() {
          status = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _listenerSubscription.cancel();
    setStatusInactive();
    super.dispose();
  }

  Future<void> setStatus() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('messageCount')
        .where('interactedBy', isEqualTo: currentUserId)
        .where('interactedTo', isEqualTo: widget.selectedUserDetailsDocumentId)
        .get();
    DocumentReference firstDocumentRef = querySnapshot.docs[0].reference;
    firstDocumentRef.update({
      'status': 'active',
    });
  }

  Future<void> setStatusInactive() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('messageCount')
        .where('interactedBy', isEqualTo: currentUserId)
        .where('interactedTo', isEqualTo: widget.selectedUserDetailsDocumentId)
        .get();
    DocumentReference firstDocumentRef = querySnapshot.docs[0].reference;
    firstDocumentRef.update({
      'status': '',
    });
  }
}
