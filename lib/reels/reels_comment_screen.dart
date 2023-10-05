import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Posts/comment_model.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';


class ReelsCommentInputSheet extends StatefulWidget {
  final String? reelCreatorId;
  final String? reelDocumentId;

  const ReelsCommentInputSheet({
    Key? key,
    required this.reelCreatorId,
    required this.reelDocumentId,
  }) : super(key: key);

  @override
  _ReelsCommentInputSheetState createState() => _ReelsCommentInputSheetState();
}

class _ReelsCommentInputSheetState extends State<ReelsCommentInputSheet> {
  final TextEditingController _commentController = TextEditingController();

  late String profileImageUrl;
  late String firstName;

  String _formatTimeDifference(Duration difference) {
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _saveComment() async {
    if (!mounted) {
      return; // Check if the widget is still mounted
    }
    String comment = _commentController.text;

    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;
    DocumentSnapshot<Map<String, dynamic>> userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData = userSnapshot.data()!;

      profileImageUrl = userData['profileImageUrl'];
      firstName = userData['firstName'];

      print('Profile Image URL: $profileImageUrl');
      print('First Name: $firstName');
      print(widget.reelCreatorId);
    } else {
      print('User with UID $userId not found.');
    }
    // Get the current date and time
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.reelDocumentId)
        .get();

    CollectionReference reelsCollection = FirebaseFirestore.instance.collection('reelsComments');
    await reelsCollection.add({
      'commentedBy':userId,
      'commentedTo':widget.reelCreatorId,
      'reelId':widget.reelDocumentId,
      'comment':comment,
      'dateTime':formattedDateTime,
      'firstName':firstName,
      'profileImageUrl':profileImageUrl,
    });
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      child: Column(
            mainAxisSize: MainAxisSize.min,  // Set to MainAxisSize.min
            children: [

                  SingleChildScrollView(
                    child: SizedBox(
                      height: 300,
                      child: SingleChildScrollView(child: CommentDisplayWidget(reelDocumentId: widget.reelDocumentId)),
                    ),
                  ),

              SizedBox(
                height: 90,  // Set a fixed height for the emoji picker
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        width: 300,
                        height: 100,
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Message....',
                          ),
                          onSubmitted: (String text) {
                            _saveComment();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        _saveComment();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 300,  // Set a fixed height for the emoji picker
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    setState(() {
                      _commentController.text += emoji.emoji;
                    });
                  },
                ),
              ),
            ],
        ),
    );
  }
}

class CommentDisplayWidget extends StatelessWidget {
   late String? reelDocumentId;
  CommentDisplayWidget( {required this.reelDocumentId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('reelsComments')
          .where('reelId', isEqualTo: reelDocumentId)
          .orderBy('dateTime', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Display a loading indicator
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No comments available.');
        } else {
          return Container(
            height: 300,
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot<Map<String, dynamic>> commentDoc =
                snapshot.data!.docs[index];
                Map<String, dynamic> commentData =
                commentDoc.data() as Map<String, dynamic>;
                print(commentData);

                // Display all fields of the document
                return Container(
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShowUserDetailsPage(
                                    userId: commentDoc.data()?['commentedBy'],
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
                                      commentDoc.data()?['profileImageUrl'],
                                      width: 30, // Increased width
                                      height: 30, // Increased height
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Text(
                                  commentDoc.data()?['firstName'],
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  commentDoc.data()?['dateTime'],
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: currentUserIsCommentedUser(commentDoc.data()?['commentedBy']),
                            child: IconButton(
                              onPressed: () {
                                deleteComment(commentDoc.id);
                              },
                              icon: const Icon(Icons.delete),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Comment: ${commentDoc.data()?['comment']}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ])
                );
              },
            ),
          );
        }
      },
    );
  }
   bool currentUserIsCommentedUser(data){
     User? user = FirebaseAuth.instance.currentUser;
     String? currentUserId = user?.uid;
     if(currentUserId==data)
       {
         return true;
       }
     return false;
   }

   Future<void> deleteComment(String documentId) async {
     try {
       // Reference to the document
       DocumentReference documentReference = FirebaseFirestore.instance
           .collection('reelsComments')
           .doc(documentId);
       await documentReference.delete();

       print('Document with ID $documentId deleted successfully.');
     } catch (e) {
       print('Error deleting document: $e');
     }
   }

}
