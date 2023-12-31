import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../home/show_user_details_page.dart';
import 'image_document_model.dart';

class Comment {
  String comment;
  String userId;
  String profileImageUrl;
  String firstName;
  String dateTime;
  String documentId;
  String imageId;

  Comment({
    required this.comment,
    required this.userId,
    required this.profileImageUrl,
    required this.firstName,
    required this.dateTime,
    required this.documentId,
    required this.imageId,
  });
}

class CommentWidget extends StatefulWidget {
  final Comment comment;

  const CommentWidget(this.comment, {super.key});

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  String? currentUserId; // Moved variable declaration
  late bool currentUserIsCommentedUser = false;
  late bool isNotDeleted=true;
  @override
  void initState() {
    super.initState();

    // Initialize currentUserId here
    User? user = FirebaseAuth.instance.currentUser;
    currentUserId = user?.uid;

    if (widget.comment.userId == currentUserId) {
      setState(() {
        currentUserIsCommentedUser = true;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isNotDeleted,
      child: Container(
          padding: const EdgeInsets.all(8.0),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ... Other parts of the widget ...
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowUserDetailsPage(
                          userId: widget.comment.userId,
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
                            widget.comment.profileImageUrl,
                            width: 30, // Increased width
                            height: 30, // Increased height
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(
                        widget.comment.firstName,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        widget.comment.dateTime,
                        style: const TextStyle(fontSize: 14.0),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: currentUserIsCommentedUser,
                  child: IconButton(
                    onPressed: () {
                      deleteComment(widget.comment.documentId, widget.comment.imageId);
                    },
                    icon: const Icon(Icons.delete),
                  ),
                )
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              'Comment: ${widget.comment.comment}',
              style: const TextStyle(fontSize: 16.0),
            ),
          ])),
    );
  }

  Future<void> deleteComment(String documentId, String imageId) async {
    try {
      await FirebaseFirestore.instance.collection('images').doc(imageId).collection('comments').doc(documentId).delete();

      DocumentSnapshot imageSnapshot = await FirebaseFirestore.instance.collection('images').doc(imageId).get();
      ImageDocument retrievedDoc = ImageDocument.fromSnapshot(imageSnapshot);
      print(retrievedDoc.commentsCount);
      retrievedDoc.commentsCount--;
      print(retrievedDoc.commentsCount);
      await FirebaseFirestore.instance.collection('images').doc(imageId).update({
        'commentsCount': retrievedDoc.commentsCount,
      });
      setState(() {
        isNotDeleted=false;
      });

      print('Document with ID $documentId deleted successfully.');
    } catch (e) {
      print('Error deleting document: $e');
    }
    setState(() {

    });

  }
}



