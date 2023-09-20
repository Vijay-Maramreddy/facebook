import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentInputSheet extends StatefulWidget {
  final String? documentsId;
  CommentInputSheet({super.key, required this.documentsId});

  @override
  _CommentInputSheetState createState() => _CommentInputSheetState();
}

class _CommentInputSheetState extends State<CommentInputSheet> {
  TextEditingController _commentController = TextEditingController();
  List<String> _comments = [];
  String? profileImageUrl;
  String? firstName;

  @override
  void initState() {
    super.initState();
    fetchComments(); // Fetch comments when the widget is initialized
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

    // Clear the comment input field and close the bottom sheet
    setState(() {
      _comments.add(comment);
      _commentController.clear();
    });
    Navigator.pop(context); // Close the bottom sheet after saving
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_comments[index]),
              );
            },
          ),

          // Text input field for adding a new comment
          TextField(
            controller: _commentController,
            decoration: InputDecoration(labelText: 'Enter your comment'),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _saveComment,
            child: Text('Save Comment'),
          ),
        ],
      ),
    );
  }

  Future<void> fetchComments() async {
    QuerySnapshot<Map<String, dynamic>> commentSnapshot =
        await FirebaseFirestore.instance.collection('images').doc(widget.documentsId).collection('comments').get();

    setState(() {
      _comments = commentSnapshot.docs.map((doc) => doc['comment'] as String).toList();
    });
  }
}
