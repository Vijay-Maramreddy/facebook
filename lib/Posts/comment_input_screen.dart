import 'dart:js_interop';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../base_page.dart';
import 'image_document_model.dart';
import 'comment_model.dart';

class CommentInputSheet extends StatefulWidget {
  final String? documentsId;

  const CommentInputSheet({Key? key, required this.documentsId}) : super(key: key);

  @override
  _CommentInputSheetState createState() => _CommentInputSheetState();
}

class _CommentInputSheetState extends State<CommentInputSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  late String profileImageUrl;
  late String firstName;
  late bool commentsVisible = true;
  String? currentUserId = "";

  Future<void> _fetchComments() async {
    QuerySnapshot<Map<String, dynamic>> commentSnapshot = await FirebaseFirestore.instance
        .collection('images')
        .doc(widget.documentsId)
        .collection('comments')
        .orderBy('dateTime', descending: true) // Order by timestamp in descending order
        .get();
    DateTime now = DateTime.now();
    commentsVisible = await isCommentsVisible(widget.documentsId);

    setState(() {
      _comments = commentSnapshot.docs.map((doc) {
        var commentDateTime = DateTime.parse(doc['dateTime'] as String);
        var difference = now.difference(commentDateTime);
        String formattedTime = _formatTimeDifference(difference);

        return Comment(
          imageId: widget.documentsId!,
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
    DocumentSnapshot imageSnapshot = await FirebaseFirestore.instance.collection('images').doc(widget.documentsId).get();
    ImageDocument retrievedDoc = ImageDocument.fromSnapshot(imageSnapshot);

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('messageCount')
        .where('interactedBy', isEqualTo: currentUserId)
        .where('interactedTo', isEqualTo: retrievedDoc.userId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      CollectionReference messages = FirebaseFirestore.instance.collection('messageCount');
      Map<String, dynamic> data1 = {
        'count': 0,
        'interactedBy': currentUserId,
        'interactedTo': retrievedDoc.userId,
        'isVanish': false,
        'status': "",
      };
      await messages.add(data1);
      Map<String, dynamic> data2 = {
        'count': 0,
        'interactedBy': retrievedDoc.userId,
        'interactedTo': currentUserId,
        'isVanish': false,
      };
      await messages.add(data2);
    }

    String comment = _commentController.text;

    DocumentSnapshot<Map<String, dynamic>> userSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData = userSnapshot.data()!;
      profileImageUrl = userData['profileImageUrl'];
      firstName = userData['firstName'];
    } else {
      print('User with UID $currentUserId not found.');
    }
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);
    Map<String, dynamic> commentData = {
      'comment': comment,
      'userId': currentUserId,
      'profileImageUrl': profileImageUrl,
      'firstName': firstName,
      'dateTime': formattedDateTime,
    };

    String groupId = combineIds(currentUserId, retrievedDoc.userId);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    await interactionsCollection.add({
      'interactedBy': currentUserId,
      'interactedWith': retrievedDoc.userId,
      'imageUrl': retrievedDoc.imageUrl,
      'message': comment,
      'groupId': groupId,
      'dateTime': DateTime.now(),
      'seenStatus': false,
      'baseText': "",
      'videoUrl': '',
      'audioUrl': '',
      'visibility': true,
      'seenBy': {},
      'isVanish': false,
    });

    await FirebaseFirestore.instance
        .collection('images')
        .doc(widget.documentsId) // Replace with the actual image document ID
        .collection('comments')
        .add(commentData);

    retrievedDoc.commentsCount++;

    FirebaseFirestore.instance.collection('images').doc(widget.documentsId).update({
      'commentsCount': retrievedDoc.commentsCount,
    });

    _comments.add(Comment(
      comment: comment,
      userId: currentUserId!,
      profileImageUrl: profileImageUrl,
      firstName: firstName,
      dateTime: formattedDateTime,
      documentId: '',
      imageId: '',
    ));
    _commentController.clear();
    if (mounted) {
      Navigator.pop(context); // Close the bottom sheet after saving
    } // Close the bottom sheet after saving
  }

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    currentUserId = user?.uid;
    _fetchComments(); // Fetch comments when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Set to MainAxisSize.min
          children: [
            // TextField(
            //   controller: _commentController,
            //   decoration: const InputDecoration(labelText: 'Enter your comment'),
            // ),
            // const SizedBox(height: 16.0),
            // ElevatedButton(
            //   onPressed: _saveComment,
            //   child: const Text('Save Comment'),
            // ),
            const SizedBox(height: 8),
            Visibility(
              visible: commentsVisible,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _comments.map((comment) {
                  return CommentWidget(comment);
                }).toList(),
              ),
            ),
            SizedBox(
              height: 100, // Set a fixed height for the emoji picker
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      width: 300,
                      height: 100,
                      child: TextField(
                        autofocus: true,
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
              height: 300, // Set a fixed height for the emoji picker
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
      ),
    );
  }

  isCommentsVisible(String? documentsId) async {
    DocumentSnapshot imageSnapshot = await FirebaseFirestore.instance.collection('images').doc(widget.documentsId).get();
    ImageDocument retrievedDoc = ImageDocument.fromSnapshot(imageSnapshot);
    bool status = retrievedDoc.status;
    if (status == true && retrievedDoc.userId != currentUserId) {
      String retrievedDocUser = retrievedDoc.userId;
      return false;
    } else {
      return true;
    }
  }
}
