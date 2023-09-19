import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'ImageDocumentModel.dart';

class ImageCollectionWidget extends StatefulWidget {
  @override
  _ImageCollectionWidgetState createState() => _ImageCollectionWidgetState();
}

class _ImageCollectionWidgetState extends State<ImageCollectionWidget> {

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
          // Process the retrieved documents and display them
          return Container(
            width: 600,
            height: 400,
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final document = snapshot.data!.docs[index];
                String documentId = snapshot.data!.docs[index].id;
                print(document['imageUrl']);
                print(documentId);
                return buildImageCard(
                  ImageDocument(
                    imageUrl: document['imageUrl'],
                    title: document['title'],
                    userId: document['userId'],
                    likes: document['likes'],
                    likedBy: (document['likedBy'] as List<dynamic>)
                        .map((isLikedBy) => isLikedBy.toString())
                        .toList(),
                    comments: (document['comments'] as List<dynamic>).map((comment) => comment.toString()).toList(),
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
    return Container(
      margin: EdgeInsets.all(10.0),
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: [

          Text('UserID: ${document.userId}'),
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
                        icon: Icon(Icons.thumb_up),
                        onPressed: () async {
                            User? user = FirebaseAuth.instance.currentUser;
                            String? userId = user?.uid;

                            // Fetch the document from Firebase
                            DocumentSnapshot imageSnapshot =
                            await FirebaseFirestore.instance.collection('images').doc(documentsId).get();
                            // String documentId=FirebaseFirestore.instance.collection('images').doc(document.imageUrl).id;

                            // Check if the document exists and retrieve its data
                            if (imageSnapshot.exists) {
                              ImageDocument retrievedDoc = ImageDocument.fromSnapshot(imageSnapshot);
                              String documentId= imageSnapshot.id;
                              print(documentId);

                                // Check if userId is in the listedBy field
                                bool userLiked = retrievedDoc.likedBy.contains(userId);
                                print(userLiked);
                                if (userLiked) {
                                  decrementLike(retrievedDoc, userId,documentId);
                                } else {
                                  incrementLike(retrievedDoc, userId,documentId);
                                }
                                setState(() {

                                 });
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
                    onPressed: () {},
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
        ],
      ),
    );
  }
  void incrementLike(ImageDocument document, String? userId, documentId) {
    // Increment likes and add userId to the listedBy field
    document.likes++;
    document.likedBy.add(userId!);

    // Update the document in Firestore
    FirebaseFirestore.instance
        .collection('images')
        .doc(documentId)
        .update({
      'likes': document.likes,
      'likedBy': document.likedBy,
    });
  }

  void decrementLike(ImageDocument document, String? userId, documentId) {
    // Decrement likes and remove userId from the listedBy field
    document.likes--;
    document.likedBy.remove(userId);

    // Update the document in Firestore
    FirebaseFirestore.instance
        .collection('images')
        .doc(documentId)
        .update({
      'likes': document.likes,
      'likedBy': document.likedBy,
    });
  }
}
