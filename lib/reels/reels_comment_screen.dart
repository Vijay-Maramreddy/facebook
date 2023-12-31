import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  Map<String, List<String>> replies = {};
  User? user = FirebaseAuth.instance.currentUser;

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
    String? currentUserId = user?.uid;
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
    CollectionReference reelsCollection = FirebaseFirestore.instance.collection('reelsComments');
    await reelsCollection.add({
      'commentedBy': currentUserId,
      'commentedTo': widget.reelCreatorId,
      'reelId': widget.reelDocumentId,
      'comment': comment,
      'dateTime': formattedDateTime,
      'firstName': firstName,
      'profileImageUrl': profileImageUrl,
      'replies': replies,
    });
    _commentController.clear();

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('messageCount')
        .where('interactedBy', isEqualTo: currentUserId)
        .where('interactedTo', isEqualTo: widget.reelCreatorId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      CollectionReference messages = FirebaseFirestore.instance.collection('messageCount');
      Map<String, dynamic> data1 = {
        'count': 0,
        'interactedBy': currentUserId,
        'interactedTo': widget.reelCreatorId,
        'isVanish': false,
        'status': "",
      };
      await messages.add(data1);
      Map<String, dynamic> data2 = {
        'count': 0,
        'interactedBy': widget.reelCreatorId,
        'interactedTo': currentUserId,
        'isVanish': false,
      };
      await messages.add(data2);
    }

  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Set to MainAxisSize.min
        children: [
          SingleChildScrollView(
            child: SizedBox(
              height: 300,
              child: SingleChildScrollView(child: CommentDisplayWidget(reelDocumentId: widget.reelDocumentId!)),
            ),
          ),
          SizedBox(
            height: 90, // Set a fixed height for the emoji picker
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
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _saveComment();
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
    );
  }
}

class CommentDisplayWidget extends StatefulWidget {
  final String? reelDocumentId;
  const CommentDisplayWidget({super.key, required this.reelDocumentId});

  @override
  _CommentDisplayWidgetState createState() => _CommentDisplayWidgetState();
}

class _CommentDisplayWidgetState extends State<CommentDisplayWidget> {
  final Map<String, TextEditingController> _replyControllers = {};
  Map<String, List<String>> replies = {};
  bool showReplies = false;
  late String currentUserName = '';
  late String currentUserProfileImage='';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('reelsComments')
          .where('reelId', isEqualTo: widget.reelDocumentId)
          .orderBy('dateTime', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Display a loading indicator
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No comments available.');
        } else {
          return SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot<Map<String, dynamic>> commentDoc = snapshot.data!.docs[index];
                Map<String, dynamic> commentData = commentDoc.data() as Map<String, dynamic>;
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
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          if (commentDoc.data()?['replies'] != null)
                            Column(
                              children: commentDoc.data()?['replies'].entries.map((entry) {
                                String key = entry.key;
                                List<dynamic> values = entry.value as List<dynamic>;

                                // Ensure each value is a String
                                List<String> stringValues = values.map((value) => value.toString()).toList();

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  SizedBox(
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ShowUserDetailsPage(
                                            userId: stringValues[0],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.blue,
                                              width: 0.1,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: Image.network(
                                              stringValues[1],
                                              width: 30,
                                              height: 30,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          stringValues[2],
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const Text("    : ")
                                      ],
                                    ),
                                  ),
                                ),
                                    Column(
                                      children: [
                                        const SizedBox(height: 12,),
                                        Row(
                                          children: [
                                            const SizedBox(width: 15,),
                                            Text(stringValues[3],style: const TextStyle(fontSize: 16)),
                                            const SizedBox(width: 20,),
                                            Text(key),
                                          ],
                                        )
                                      ],
                                    )

                                  ],
                                );
                              }).toList().cast<Widget>(),  // Cast the list to List<Widget>
                            )
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _replyControllers[commentDoc.id] = TextEditingController();
                          });
                        },
                        child: const Text('Reply'),
                      ),
                      if (_replyControllers[commentDoc.id] != null)
                        Column(
                          children: [
                            TextField(
                              controller: _replyControllers[commentDoc.id],
                              decoration: const InputDecoration(
                                hintText: 'Add a reply...',
                              ),
                              onSubmitted: (String reply) async {
                                if(commentDoc.data()?['replies']!=null) {
                                  replies = convertReplies(commentData['replies']);
                                }
                                User? user = FirebaseAuth.instance.currentUser;
                                String? currentUserId = user?.uid;
                                await getCurrentUserName(userId: currentUserId);
                                List<String> newReplyData = [currentUserId!,currentUserProfileImage,currentUserName, reply];
                                DateTime now = DateTime.now();
                                String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);
                                replies[formattedDateTime] = newReplyData;
                                updateReplies(replies: replies, commentId: commentDoc.id);
                                setState(() {
                                  replies = {};
                                  _replyControllers[commentDoc.id]!.clear();
                                  currentUserName = '';
                                });
                              },
                            ),
                          ],
                        ),

                    ]));
              },
            ),
          );
        }
      },
    );
  }

  bool currentUserIsCommentedUser(data) {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    if (currentUserId == data) {
      return true;
    }
    return false;
  }

  Future<void> deleteComment(String documentId) async {
    try {
      // Reference to the document
      DocumentReference documentReference = FirebaseFirestore.instance.collection('reelsComments').doc(documentId);
      await documentReference.delete();

      print('Document with ID $documentId deleted successfully.');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }


  Future<void> updateReplies({required Map<String, List<String>> replies, required String commentId}) async {
    await FirebaseFirestore.instance.collection('reelsComments').doc(commentId).update({
      'replies': replies,
    });
  }

  Future<void> getCurrentUserName({String? userId}) async {
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (documentSnapshot.exists) {
      Map<String, dynamic> data = documentSnapshot.data()!;
      setState(() {
        currentUserName = data['firstName'];
        currentUserProfileImage=data['profileImageUrl'];
      });

      print("current user is $currentUserName");
    }
  }

  Map<String, List<String>> convertReplies(dynamic repliesData) {
    Map<String, List<String>> convertedReplies = {};

    if (repliesData is Map) {
      repliesData.forEach((key, value) {
        if (value is List) {
          List<String> stringValues = value.map((val) => val.toString()).toList();
          convertedReplies[key] = stringValues;
        }
      });
    }

    return convertedReplies;
  }


}
