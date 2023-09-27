import 'dart:async';
import 'package:facebook/Posts/comment_input_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';
import 'image_document_model.dart';

class StatusCollectionWidget extends StatefulWidget {
  late bool? showOnlyCurrentUserPosts;
  StatusCollectionWidget({super.key, required this.showOnlyCurrentUserPosts});

  @override
  _StatusCollectionWidgetState createState() => _StatusCollectionWidgetState();
}

class _StatusCollectionWidgetState extends State<StatusCollectionWidget> {
  late String profileImageUrl = '';
  late String firstName = '';

  @override
  Widget build(BuildContext context) {
    Stream streams = FirebaseFirestore.instance.collection('images').where('status', isEqualTo: true).snapshots();
    return SingleChildScrollView(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('images')
            .where('status', isEqualTo: true)
            // .orderBy('status')
            .orderBy('dateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text('No data available');
          }
          return Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            width: 800,
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final document = snapshot.data!.docs[index];
                String documentId = snapshot.data!.docs[index].id;
                DateTime now = DateTime.now();
                var commentDateTime = DateTime.parse(document['dateTime'] as String);
                var difference = now.difference(commentDateTime);
                if (difference.inHours >= 24) {
                  deletePost(documentId);
                  return null;
                } else {
                }
                String formattedTime = _formatTimeDifference(difference);

                return buildImageCard(
                  ImageDocument(
                    imageUrl: document['imageUrl'],
                    title: document['title'],
                    userId: document['userId'],
                    likes: document['likes'],
                    likedBy: (document['likedBy'] as List<dynamic>).map((isLikedBy) => isLikedBy.toString()).toList(),
                    firstName: document['firstName'],
                    profileImageUrl: document['profileImageUrl'],
                    commentsCount: document['commentsCount'],
                    dateTime: formattedTime,
                    status: document['status'],
                  ),
                  documentsId: documentId,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildImageCard(ImageDocument document, {required String documentsId}) {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    late bool alreadyLiked = (document.likedBy.contains(currentUserId));
    bool currentUserIsViewingUser = false;
    if (document.userId == currentUserId) {
      currentUserIsViewingUser = true;
    }
    return Visibility(
      visible: isVisible(document.userId),
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
                      width: 30, // Increased width
                      height: 30, // Increased height
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue,
                          width: 0.1,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          document.profileImageUrl,
                          width: 30, // Increased width
                          height: 30, // Increased height
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Text(
                      document.firstName,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      document.dateTime,
                      style: const TextStyle(fontSize: 14.0),
                    ),
                    Visibility(
                      visible: currentUserIsViewingUser,
                      child: IconButton(
                          onPressed: () {
                            deletePost(documentsId);
                          },
                          icon: const Icon(Icons.delete)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              double screenWidth = MediaQuery.of(context).size.width;
              double screenHeight = MediaQuery.of(context).size.height;
              double dialogWidth = screenWidth * 0.5; // Adjust the percentage as needed
              double dialogHeight = screenHeight * 0.5; // Adjust the percentage as needed
              // Show a dialog or a full-screen view to display the image in a larger format
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    child: Column(children: [
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close)),
                      const SizedBox(
                        height: 50,
                      ),
                      Text(
                        'Title: ${document.title}',
                        style: const TextStyle(fontSize: 40, color: Colors.blue),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        width: dialogWidth,
                        height: dialogHeight,
                        child: Image.network(
                          document.imageUrl,
                          width: 1600,
                          height: 1600,
                          fit: BoxFit.contain,
                        ),
                      ),
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.thumb_up, color: alreadyLiked ? Colors.blue : Colors.black),
                                    onPressed: () async {
                                      User? user = FirebaseAuth.instance.currentUser;
                                      String? userId = user?.uid;

                                      DocumentSnapshot imageSnapshot = await FirebaseFirestore.instance.collection('images').doc(documentsId).get();

                                      if (imageSnapshot.exists) {
                                        ImageDocument retrievedDoc = ImageDocument.fromSnapshot(imageSnapshot);
                                        String documentId = imageSnapshot.id;

                                        bool userLiked = retrievedDoc.likedBy.contains(userId);
                                        if (userLiked) {
                                          decrementLike(retrievedDoc, userId, documentId);
                                        } else {
                                          incrementLike(retrievedDoc, userId, documentId);
                                        }
                                        setState(() {
                                          alreadyLiked = !alreadyLiked;
                                        });
                                      }
                                    },
                                  ),
                                  Visibility(
                                    visible: isCountVisible(document.userId),
                                    child: Text('Likes: ${document.likes}'),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.comment),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return CommentInputSheet(
                                            documentsId: documentsId,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Visibility(
                                    visible: isCountVisible(document.userId),
                                    child: Text('Comments: ${document.commentsCount}'),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share),
                                    onPressed: () {},
                                  ),
                                  Text('Shares: ${document.sharesCount}'),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ]),
                  );
                },
              );
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
    );
  }

  bool isVisible(String userId) {
    if (widget.showOnlyCurrentUserPosts == true) {
      User? user = FirebaseAuth.instance.currentUser;
      String? CurrentuserId = user?.uid;
      if (CurrentuserId != userId) {
        return false;
      }
    }
    return true;
  }

  isCountVisible(String userId) {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    if (currentUserId == userId) {
      return true;
    }
    return false;
  }

  Future<void> deletePost(String documentId) async {
    try {
      // Access the collection and delete the document with the given ID
      await FirebaseFirestore.instance.collection('images').doc(documentId).delete();
      setState(() {});

    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  void incrementLike(ImageDocument document, String? userId, documentId) async {
    // Increment likes and add userId to the listedBy field
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);
    document.likes++;
    document.likedBy.add(userId!);

    // Update the document in Firestore
    FirebaseFirestore.instance.collection('images').doc(documentId).update({
      'likes': document.likes,
      'likedBy': document.likedBy,
    });
    String groupId=combineIds(userId,document.userId);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    String message="liked the status";
    await interactionsCollection.add({
      'interactedBy': userId,
      'interactedWith':document.userId,
      'imageUrl':document.imageUrl,
      'dateTime':formattedDateTime,
      'message':message,
      'groupId':groupId,
    });
  }

  void decrementLike(ImageDocument document, String? userId, documentId) {
    // Decrement likes and remove userId from the listedBy field
    document.likes--;
    document.likedBy.remove(userId);

    FirebaseFirestore.instance.collection('images').doc(documentId).update({
      'likes': document.likes,
      'likedBy': document.likedBy,
    });
  }

  fetchUserDetails({required String userId}) async {
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
    // Query the collection to find documents that match the provided mobile number
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
}
