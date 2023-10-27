import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../app_style.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';
import 'image_document_model.dart';

import 'image_page_view_dialog.dart';

class StatusCollectionWidget extends StatefulWidget {
  final bool? showOnlyCurrentUserPosts;
  late List<String> friendsIds;
  final VoidCallback? onUploadStatus;

  StatusCollectionWidget({super.key, required this.showOnlyCurrentUserPosts, required this.friendsIds, this.onUploadStatus});

  @override
  _StatusCollectionWidgetState createState() => _StatusCollectionWidgetState();
}

class _StatusCollectionWidgetState extends State<StatusCollectionWidget> {

  late String profileImageUrl = '';
  late String firstName = '';
  late List<String> allFriendsIds = widget.friendsIds;
  bool status = true;
  late Uint8List _image;
  late Uint8List imageFile;
  late String title;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? user = FirebaseAuth.instance.currentUser;

  Map<String, DocumentSnapshot> snapshotMap = {};

  @override
  void initState() {
    fetchFriends();
    // deleteStatusAfterTimeLimit();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (allFriendsIds.isEmpty) {
      fetchFriends();
    }
    if (!snapshotMap.containsKey(user?.uid)) {
      return Row(
        children: [
          GestureDetector(
            onTap: uploadAStatus,
            child: ClipOval(
              child: Image.network(
                "assets/newStatusLogo.png",
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            width: 680,
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshotMap.length,
              itemBuilder: (context, index) {
                final List<String> documentIds = snapshotMap.keys.toList();
                final String documentId = documentIds[index];
                final DocumentSnapshot<Object?>? document = snapshotMap[documentId];
                final String postUserId = document?['userId'];

                return FutureBuilder<UserProfileDetails>(
                  future: getProfileDetails(postUserId),
                  builder: (context, profileDetailsSnapshot) {
                    if (profileDetailsSnapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (profileDetailsSnapshot.hasError) {
                      return Text('Error: ${profileDetailsSnapshot.error}');
                    } else {
                      DateTime now = DateTime.now();
                      var commentDateTime = DateTime.parse(document?['dateTime'] as String);
                      var difference = now.difference(commentDateTime);
                      if (difference.inHours >= 48) {
                        deletePost(document!.id);
                        return Container();
                      } else {}
                      String formattedTime = _formatTimeDifference(difference);
                      UserProfileDetails? userDetails = profileDetailsSnapshot.data;
                      String? profileImageUrl = userDetails?.profileImageUrl;
                      String? firstName = userDetails?.firstName;
                      return buildImageCard(
                        ImageDocument(
                          imageUrl: document?['imageUrl'],
                          title: document?['title'],
                          userId: document?['userId'],
                          likes: document?['likes'],
                          likedBy: (document?['likedBy'] as List<dynamic>).map((isLikedBy) => isLikedBy.toString()).toList(),
                          commentsCount: document?['commentsCount'],
                          dateTime: formattedTime,
                          status: document?['status'],
                        ),
                        documentsId: documentId,
                        postProfileImageUrl: profileImageUrl,
                        postFirstName: firstName,
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
        width: 800,
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: snapshotMap.length,
          itemBuilder: (context, index) {
            final List<String> documentIds = snapshotMap.keys.toList();
            final String documentId = documentIds[index];
            final DocumentSnapshot<Object?>? document = snapshotMap[documentId];
            final String postUserId = document?['userId'];

            return FutureBuilder<UserProfileDetails>(
              future: getProfileDetails(postUserId),
              builder: (context, profileDetailsSnapshot) {
                if (profileDetailsSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (profileDetailsSnapshot.hasError) {
                  return Text('Error: ${profileDetailsSnapshot.error}');
                } else {
                  DateTime now = DateTime.now();
                  var commentDateTime = DateTime.parse(document?['dateTime'] as String);
                  var difference = now.difference(commentDateTime);
                  if (difference.inHours >= 48) {
                    deletePost(document!.id);
                    return Container();
                  } else {}
                  String formattedTime = _formatTimeDifference(difference);
                  UserProfileDetails? userDetails = profileDetailsSnapshot.data;
                  String? profileImageUrl = userDetails?.profileImageUrl;
                  String? firstName = userDetails?.firstName;
                  return buildImageCard(
                    ImageDocument(
                      imageUrl: document?['imageUrl'],
                      title: document?['title'],
                      userId: document?['userId'],
                      likes: document?['likes'],
                      likedBy: (document?['likedBy'] as List<dynamic>).map((isLikedBy) => isLikedBy.toString()).toList(),
                      commentsCount: document?['commentsCount'],
                      dateTime: formattedTime,
                      status: document?['status'],
                    ),
                    documentsId: documentId,
                    postProfileImageUrl: profileImageUrl,
                    postFirstName: firstName,
                  );
                }
              },
            );
          },
        ),
      );
    }
  }

  void uploadAStatus() {
    status = true;
    uploadImageAndSaveUrl().then((_) {
      setState(() {
        performQuery();
      });
    });
  }

  uploadImageAndSaveUrl() async {
    imageFile = await pickImageFromGallery();

    if (imageFile != null) {
      String? title = await _showImagePickerDialog();
      int likes = 0;

      List<String> likedBy = [];
      late String profileImageUrl;
      late String firstName;
      int commentsCount = 0;
      String uuid = AppStyles.uuid();
      DateTime now = DateTime.now();
      String dateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);
      String? imageUrl = await uploadImageToStorage('postImages/$uuid', imageFile);
      int shareCount = 0;
      if (imageUrl != null) {
        CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          DocumentSnapshot documentSnapshot = await usersCollection.doc(user.uid).get();
          if (documentSnapshot.exists) {
            Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;
            if (data != null) {
              profileImageUrl = data['profileImageUrl'];
              firstName = data['firstName'];
            } else {
              if (kDebugMode) {
                print('Document data is null.');
              }
            }
          } else {
            String message = "user details not found";
            showAlert(context, message);
          }
          await addImageUrlToFirebase(
              user.uid, imageUrl, title!, likes, commentsCount, dateTime, likedBy, profileImageUrl, firstName, status, shareCount);
          setState(() {});
        } else {
          if (kDebugMode) {
            print('Error: User is not authenticated.');
          }
        }
      } else {
        if (kDebugMode) {
          print('Error uploading image.');
        }
      }
    } else {
      if (kDebugMode) {
        print('No image picked.');
      }
    }
  }

  Future<void> addImageUrlToFirebase(String userId, String imageUrl, String title, int likes, int commentsCount, String dateTime,
      List<String> likedBy, String profileImageUrl, String firstName, bool status, int shareCount) async {
    final CollectionReference imagesCollection = FirebaseFirestore.instance.collection('images');

    // Add a new document to the 'images' collection
    await imagesCollection.add({
      'imageUrl': imageUrl,
      'userId': userId,
      'title': title,
      'likes': likes,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'dateTime': dateTime,
      'profileImageUrl': profileImageUrl,
      'firstName': firstName,
      'status': status,
      'sharesCount': shareCount,
    });
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

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<Uint8List> pickImageFromGallery() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    _image = img;
    return _image;
  }

  Widget buildImageCard(ImageDocument document, {required String documentsId, required String? postProfileImageUrl, required String? postFirstName}) {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;

    bool currentUserIsViewingUser = false;
    if (document.userId == currentUserId) {
      currentUserIsViewingUser = true;
    }
    fetchUserDetails(userId: document.userId);
    return Visibility(
      visible: isVisible(document.userId),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowUserDetailsPage(
                          userId: document.userId,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 25, // Increased width
                        height: 25, // Increased height
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue,
                            width: 0.1,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            postProfileImageUrl!,
                            width: 25, // Increased width
                            height: 25, // Increased height
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        postFirstName!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        document.dateTime,
                        style: const TextStyle(fontSize: 13.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () async {
                QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                    .collection('images')
                    .where('userId', isEqualTo: document.userId)
                    .where('status', isEqualTo: true)
                    .orderBy('dateTime', descending: true)
                    .get();

                if (querySnapshot.docs.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ImagePageViewDialog(
                        querySnapshot: querySnapshot,
                        initialIndex: 0,
                      );
                    },
                  );
                }
              },
              child: ClipOval(
                child: Image.network(
                  document.imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onPressedUploadStatus() {
    if (widget.onUploadStatus != null) {
      widget.onUploadStatus!();
    }
  }

  bool isVisible(String userId) {
    if (widget.showOnlyCurrentUserPosts == true) {
      User? user = FirebaseAuth.instance.currentUser;
      String? currentUserId = user?.uid;
      if (currentUserId != userId) {
        return false;
      }
    }
    if (allFriendsIds.isEmpty) {
      return true;
    }
    if (allFriendsIds.contains(userId)) {
      return true;
    } else {
      return false;
    }
    return true;
  }

  fetchUserDetails({required String userId}) async {
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
    DocumentSnapshot documentSnapshot = await usersCollection.doc(userId).get();
    if (documentSnapshot.exists) {
      Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;
      if (data != null) {
        profileImageUrl = data['profileImageUrl'];
        firstName = data['firstName'];
      } else {
        print('Document data is null.');
      }
    } else {
      String message = "user details not found";
      showAlert(context, message);
    }
  }

  String _formatTimeDifference(Duration difference) {
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Future<void> performQuery() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('images')
        .where('status', isEqualTo: true)
        .where('userId', whereIn: allFriendsIds)
        .orderBy('dateTime')
        .get();

    for (var document in querySnapshot.docs) {
      snapshotMap[document['userId']] = document;
    }
    setState(() {
      snapshotMap;
    });
  }

  Future<void> deletePost(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('images').doc(documentId).delete();
      setState(() {
        performQuery();
      });
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  void fetchFriends() {
    allFriendsIds = widget.friendsIds;
    setState(() {
      allFriendsIds;
    });
    if (allFriendsIds.isNotEmpty) {
      performQuery();
    }
  }

  // Future<void> deleteStatusAfterTimeLimit() async {
  //   QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //       .collection('images')
  //       .where('status', isEqualTo: true)
  //       .where('userId', whereIn: allFriendsIds)
  //       .orderBy('dateTime')
  //       .get();
  //   for (var document in querySnapshot.docs) {
  //     DateTime now = DateTime.now();
  //     var commentDateTime = DateTime.parse(document['dateTime'] as String);
  //     var difference = now.difference(commentDateTime);
  //     if (difference.inHours >= 48) {
  //       deletePost(document.id);
  //     }
  //   }
  // }
}
