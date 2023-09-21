import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'ImageDocumentModel.dart';
import 'comment_model.dart';

class CommentInputSheet extends StatefulWidget {
  final String? documentsId;

  CommentInputSheet({Key? key, required this.documentsId}) : super(key: key);

  @override
  _CommentInputSheetState createState() => _CommentInputSheetState();
}

class _CommentInputSheetState extends State<CommentInputSheet> {
  TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  late String profileImageUrl;
  late String firstName;

  Future<void> _fetchComments() async {
    QuerySnapshot<Map<String, dynamic>> commentSnapshot =
    await FirebaseFirestore.instance
        .collection('images')
        .doc(widget.documentsId)
        .collection('comments')
        .orderBy('dateTime', descending: true) // Order by timestamp in descending order
        .get();
    DateTime now = DateTime.now();

    setState(() {
      _comments = commentSnapshot.docs.map((doc) {
        var commentDateTime = DateTime.parse(doc['dateTime'] as String);
        var difference = now.difference(commentDateTime);
        String formattedTime = _formatTimeDifference(difference);

        return Comment(
          imageId:widget.documentsId!,
          documentId: doc.id, // Pass the document ID
          comment: doc['comment'] as String,
          userId: doc['userId'] as String,
          profileImageUrl: doc['profileImageUrl'] as String,
          firstName: doc['firstName'] as String,
          dateTime: formattedTime,
        );
      }).toList();
    });
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

  void _saveComment() async {
    String comment = _commentController.text;

    // Get the current user's information
    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;
    DocumentSnapshot<Map<String, dynamic>> userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData = userSnapshot.data()!;
      // Access individual fields
      profileImageUrl = userData['profileImageUrl'];
      firstName = userData['firstName'];

      print('Profile Image URL: $profileImageUrl');
      print('First Name: $firstName');
      print(widget.documentsId);
    } else {
      print('User with UID $userId not found.');
    }
    // Get the current date and time
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    // Create a map to store the comment data
    Map<String, dynamic> commentData = {
      'comment': comment,
      'userId': userId,
      'profileImageUrl': profileImageUrl,
      'firstName': firstName,
      'dateTime': formattedDateTime,
    };

    // Save the comment to the Firestore collection
    await FirebaseFirestore.instance
        .collection('images')
        .doc(widget.documentsId) // Replace with the actual image document ID
        .collection('comments')
        .add(commentData);
    DocumentSnapshot imageSnapshot = await FirebaseFirestore.instance.collection('images').doc(widget.documentsId).get();
    ImageDocument retrievedDoc = ImageDocument.fromSnapshot(imageSnapshot);
    retrievedDoc.commentsCount++;

    FirebaseFirestore.instance.collection('images').doc(widget.documentsId).update({
      'commentsCount': retrievedDoc.commentsCount,
    });

    setState(() {
      _comments.add(Comment(
        comment: comment,
        userId: userId!,
        profileImageUrl: profileImageUrl,
        firstName: firstName,
        dateTime: formattedDateTime,
        documentId: '',
        imageId: '',
      ));
      _commentController.clear();
    });
    Navigator.pop(context); // Close the bottom sheet after saving
  }

  @override
  void initState() {
    super.initState();
    _fetchComments(); // Fetch comments when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _commentController,
              decoration: InputDecoration(labelText: 'Enter your comment'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _saveComment,
              child: Text('Save Comment'),
            ),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _comments.map((comment) {
                return CommentWidget(comment);
              }).toList(),
            ), // Text input field for adding a new comment
          ],
        ),
      ),
    );
  }
}

