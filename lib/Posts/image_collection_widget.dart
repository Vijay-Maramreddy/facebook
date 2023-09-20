import 'dart:typed_data';

import 'package:facebook/Posts/comment_input_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';
import 'image_document_model.dart';

class ImageCollectionWidget extends StatefulWidget {
  @override
  _ImageCollectionWidgetState createState() => _ImageCollectionWidgetState();
}

class _ImageCollectionWidgetState extends State<ImageCollectionWidget> {
  late String profileImageUrl = '';
  late String firstName = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('images').snapshots(),
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
                List<dynamic> commentsData = document['comments'];
                return buildImageCard(
                  ImageDocument(
                    imageUrl: document['imageUrl'],
                    title: document['title'],
                    userId: document['userId'],
                    likes: document['likes'],
                    likedBy: (document['likedBy'] as List<dynamic>).map((isLikedBy) => isLikedBy.toString()).toList(),
                    // comments: (document['comments'] as List<dynamic>).map((comment) => comment.toString()).toList(),

                  comments : commentsData
                      .map<List<String>>((comment) => List<String>.from(comment))
                    .toList(),
                    // comments : commentsData.map((comment) => [comment]).toList();
                    firstName: document['firstName'],
                    profileImageUrl: document['profileImageUrl'],
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
    late bool alreadyLiked = (document.likedBy.contains(document.userId));

    return Container(
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
                  child: Container(
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
                ),
                Text(
                  document.firstName,
                  style: TextStyle(fontSize: 20),
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
          Row(
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
                        setState(() {});
                      }
                    },
                  ),
                  Text('Likes: ${document.likes}'),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.comment),
                    onPressed: () {
                      showModalBottomSheet(context: context, builder: (BuildContext context){
                        return CommentInputSheet( documentsId:documentsId,);
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
                    onPressed: () {
                    },
                  ),
                  Text('Shares: ${document.sharesCount}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
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
}
