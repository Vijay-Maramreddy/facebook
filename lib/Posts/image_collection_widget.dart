import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:facebook/Posts/comment_input_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';
import 'image_document_model.dart';

class ImageCollectionWidget extends StatefulWidget {
  late bool? showOnlyCurrentUserPosts;
  ImageCollectionWidget({required this.showOnlyCurrentUserPosts});

  @override
  _ImageCollectionWidgetState createState() => _ImageCollectionWidgetState();
}

class _ImageCollectionWidgetState extends State<ImageCollectionWidget> {
  late String profileImageUrl = '';
  late String firstName = '';
  List<String> userIdList = [];
  Map<String, List<String>> userDataMap = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    getDetails(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    Stream streams = FirebaseFirestore.instance
        .collection('images')
        .where('status', isNotEqualTo: 'true')
        .orderBy('status')
        .orderBy('dateTime', descending: true)
        .snapshots();
    return SingleChildScrollView(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('images')
            .where('status', isNotEqualTo: true)
            .orderBy('status')
            .orderBy('dateTime', descending: true) // Order by dateTime in descending order
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
            width: 800,
            height: 380,
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final document = snapshot.data!.docs[index];
                String documentId = snapshot.data!.docs[index].id;
                String postUserId = document['userId'];

                return FutureBuilder<UserProfileDetails>(
                  future: getProfileDetails(postUserId),
                  builder: (context, profileDetailsSnapshot) {
                    if (profileDetailsSnapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (profileDetailsSnapshot.hasError) {
                      return Text('Error: ${profileDetailsSnapshot.error}');
                    } else {
                      DateTime now = DateTime.now();
                      var commentDateTime = DateTime.parse(document['dateTime'] as String);
                      var difference = now.difference(commentDateTime);
                      String formattedTime = _formatTimeDifference(difference);
                      UserProfileDetails? userDetails = profileDetailsSnapshot.data;
                      String? profileImageUrl = userDetails?.profileImageUrl;
                      String? firstName = userDetails?.firstName;
                      return buildImageCard(
                        ImageDocument(
                          imageUrl: document['imageUrl'],
                          title: document['title'],
                          userId: document['userId'],
                          likes: document['likes'],
                          likedBy: (document['likedBy'] as List<dynamic>).map((isLikedBy) => isLikedBy.toString()).toList(),
                          // firstName: document['firstName'],
                          // profileImageUrl: document['profileImageUrl'],
                          commentsCount: document['commentsCount'],
                          dateTime: formattedTime,
                          status: document['status'],
                          sharesCount: document['sharesCount'],
                        ),
                        documentsId: documentId,
                        postProfileImageUrl: profileImageUrl,
                        postFirstName:firstName,
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }



  Widget buildImageCard(ImageDocument document, {required String documentsId, String? postProfileImageUrl, String? postFirstName}) {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    late bool alreadyLiked = (document.likedBy.contains(currentUserId));
    bool currentUserIsViewingUser = false;
    if (document.userId == currentUserId) {
      currentUserIsViewingUser = true;
    }
    int sharesCount=document.sharesCount as int;
    print(sharesCount);
    return Visibility(
      visible: isVisible(document.userId),
      child: Container(
        margin: const EdgeInsets.all(10.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10.0),
        ),
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
                            postProfileImageUrl!,
                            width: 30, // Increased width
                            height: 30, // Increased height
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(
                        postFirstName!,
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
            Text('Title: ${document.title}'),
            CachedNetworkImage(
              imageUrl: document.imageUrl,

            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
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
                    Text('Comments: ${document.commentsCount}'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.black),
                      onPressed: () {
                        updateSharesCount(documentsId,document);

                        final linkToShare = Uri.encodeComponent(document.imageUrl);
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Container(
                              child: Wrap(
                                children: <Widget>[
                                  ListTile(
                                    leading: const Icon(Icons.send),
                                    title: const Text('Share on WhatsApp'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      shareOnWhatsApp(linkToShare);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.send),
                                    title: const Text('Share on Facebook'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      shareOnFacebook(linkToShare);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.send),
                                    title: const Text('Share on Telegram'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      shareOnTelegram(linkToShare);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.send),
                                    title: const Text('Share with friends'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showDialog(context, document.imageUrl);
                                      // shareToFriends(linkToShare);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Text('$sharesCount',style: TextStyle(color: Colors.black)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  bool isVisible(String userId) {
    if (widget.showOnlyCurrentUserPosts == true) {
      User? user = FirebaseAuth.instance.currentUser;
      String? currentUserId = user?.uid;
      if (currentUserId != userId) {
        return false;
      }
    }
    return true;
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
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    document.likes++;
    document.likedBy.add(userId!);

    await FirebaseFirestore.instance.collection('images').doc(documentId).update({
      'likes': document.likes,
      'likedBy': document.likedBy,
    });

    String groupId = combineIds(userId, document.userId);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    String message = "liked the post";
    await interactionsCollection.add({
      'interactedBy': userId,
      'interactedWith': document.userId,
      'imageUrl': document.imageUrl,
      'dateTime': formattedDateTime,
      'message': message,
      'groupId': groupId,
    });
    // String Id=document.userId;
    await FirebaseFirestore.instance.collection('users').doc(document.userId).update({
      'dateTime': formattedDateTime,
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


  String _formatTimeDifference(Duration difference) {
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }


  Future<void> _showDialog(BuildContext context, String linkToShare) {
    late List<String> userIds = [];
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Users'),
          content: SingleChildScrollView(
              child: Column(
                children: userDataMap.keys.map((userId) {
                  String firstName = userDataMap[userId]![0];
                  bool isChecked = userIds.contains(userId);

                  return ListTile(
                    title: Text(firstName),
                    leading: Checkbox(
                      value: isChecked,
                      onChanged: (bool? newvalue) {
                        print(userIds);
                        print(userId);
                        print('Checkbox value: $newvalue');
                        setState(() {
                          if (newvalue != null) {
                            if (newvalue) {
                              userIds.add(userId);
                            } else {
                              userIds.remove(userId);
                            }
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              )),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                shareLinkToAllFriends(userIds, linkToShare);
                Navigator.of(context).pop(userIds);
              },
            ),
          ],
        );
      },
    );
  }

  void shareLinkToAllFriends(List<String> userIds, String linkToShare) {
    for (String userId in userIds) {
      sendPostImageUrl(userId, linkToShare);
    }
  }

  void sendPostImageUrl(String userId,String imageLink) async {
    int count;
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;

    CollectionReference messageCount = FirebaseFirestore.instance.collection('messageCount');

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await messageCount
        .where('interactedBy', isEqualTo: currentUserId)
        .where('interactedTo', isEqualTo: userId)
        .get() as QuerySnapshot<Map<String, dynamic>>;
    DocumentSnapshot<Map<String, dynamic>> doc = querySnapshot.docs.first;
    count = doc['count'];
    count = count + 1;
    await doc.reference.update({'count': count});
    // await doc.reference.update({'count': currentCount + 1});

    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    String? videoLink = '';
    String text ="Check Out This Post";
    String groupId = combineIds(currentUserId, userId);
    if (text.isNotEmpty) {
      await interactionsCollection.add({
        'interactedBy': currentUserId,
        'interactedWith': userId,
        'imageUrl': imageLink,
        'dateTime': formattedDateTime,
        'message': text,
        'groupId': groupId,
        'videoUrl': "",
        'visibility': true,
      });
    }
  }

  Future<void> getDetails(String? currentUserId) async {
    userIdList = (await FirebaseFirestore.instance.collection('users').doc(currentUserId).get()).data()?['friends']?.cast<String>() ?? [];

    for (String userId in userIdList) {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData = userSnapshot.data()!;
        String firstName = userData['firstName'];
        String profileImageUrl = userData['profileImageUrl'];
        userDataMap[userId] = [firstName, profileImageUrl];
      }
    }
  }

  Future<void> updateSharesCount(String documentsId, ImageDocument document) async {
    int shareCount=document.sharesCount;
    print('before increment $document.sharesCount');
    shareCount++;
    print("after increment $shareCount");
    await FirebaseFirestore.instance.collection('images').doc(documentsId).update({
      "sharesCount":shareCount,
    });
  }
}


