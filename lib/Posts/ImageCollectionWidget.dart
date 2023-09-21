import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:facebook/Posts/comment_input_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';
import 'ImageDocumentModel.dart';

class ImageCollectionWidget extends StatefulWidget {
  late bool? showOnlyCurrentUserPosts;
  ImageCollectionWidget({required this.showOnlyCurrentUserPosts});

  @override
  _ImageCollectionWidgetState createState() => _ImageCollectionWidgetState();
}

class _ImageCollectionWidgetState extends State<ImageCollectionWidget> {

  late String profileImageUrl = '';
  late String firstName = '';


  @override
  Widget build(BuildContext context) {
    print(widget.showOnlyCurrentUserPosts);
    Stream streams=FirebaseFirestore.instance
        .collection('images')
        .orderBy('dateTime', descending: true)  // Order by dateTime in descending order
        .snapshots();
    return SingleChildScrollView(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('images')
            .orderBy('dateTime', descending: true)  // Order by dateTime in descending order
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Text('No data available');
          }
          return Container(
            width: 600,
            height: 400,
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final document = snapshot.data!.docs[index];
                String documentId = snapshot.data!.docs[index].id;
                print(documentId);
                DateTime now = DateTime.now();
                var commentDateTime = DateTime.parse(document['dateTime'] as String);
                var difference = now.difference(commentDateTime);
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
    String? CurrentuserId = user?.uid;
    late bool alreadyLiked = (document.likedBy.contains(CurrentuserId));
    bool currentUserIsViewingUser=false;
    if(document.userId==CurrentuserId)
      {
        currentUserIsViewingUser=true;
      }
    return Visibility(
      visible:isVisible(document.userId),
      child: Container(
        margin: EdgeInsets.all(10.0),
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          children: [
            Container(
              child: Row(
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
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          document.dateTime,
                          style: TextStyle(fontSize: 14.0),
                        ),
                        Visibility(
                          visible: currentUserIsViewingUser ,
                          child: IconButton(
                                onPressed: (){
                                  deletePost(documentsId);
                                  },
                                icon: Icon(Icons.delete)
                            ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text('Title: ${document.title}'),
            CachedNetworkImage(
              imageUrl: document.imageUrl,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 10.0),
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
                              print(documentId);

                              bool userLiked = retrievedDoc.likedBy.contains(userId);
                              print(userLiked);
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
                        Text('Likes: ${document.likes}'),
                      ],
                    ),

                    // ... Existing code ...
                  ],
                );
              },
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.comment),
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
                Text('Comments: ${document.commentsCount}'),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {},
                ),
                Text('Shares: ${document.sharesCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  bool isVisible(String userId){
    if(widget.showOnlyCurrentUserPosts==true)
      {
        User? user = FirebaseAuth.instance.currentUser;
        String? CurrentuserId = user?.uid;
        if(CurrentuserId!=userId)
          {
            return false;
          }
      }
    return true;
  }

  Future<void> deletePost(String documentId) async {
    try {
      // Access the collection and delete the document with the given ID
      await FirebaseFirestore.instance
          .collection('images')
          .doc(documentId)
          .delete();
      setState(() {

      });

      print('Document with ID $documentId deleted successfully.');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  void incrementLike(ImageDocument document, String? userId, documentId) {
    // Increment likes and add userId to the listedBy field
    document.likes++;
    document.likedBy.add(userId!);

    // Update the document in Firestore
    FirebaseFirestore.instance.collection('images').doc(documentId).update({
      'likes': document.likes,
      'likedBy': document.likedBy,
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
    print("inside fetchuesrDetails of: $userId");

    CollectionReference usersCollection = await FirebaseFirestore.instance.collection('users');
    // Query the collection to find documents that match the provided mobile number
    DocumentSnapshot documentSnapshot = await usersCollection.doc(userId).get();
    if (documentSnapshot.exists) {
      Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;
      if (data != null) {
        profileImageUrl = data['profileImageUrl'];
        firstName = data['firstName'];

        print('userProfilePicUrl: $profileImageUrl');
        print('Name: $firstName');
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




