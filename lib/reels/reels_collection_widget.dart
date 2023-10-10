import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:facebook/Posts/comment_input_screen.dart';
import 'package:facebook/reels/reels_comment_screen.dart';
import 'package:facebook/reels/video_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';
import 'dart:convert';

class ReelsCollectionWidget extends StatefulWidget {
  ReelsCollectionWidget();

  @override
  _ReelsCollectionWidgetState createState() => _ReelsCollectionWidgetState();
}

class _ReelsCollectionWidgetState extends State<ReelsCollectionWidget> {
  late String profileImageUrl = '';
  late String firstName = '';
  List<String> userIdList = [];
  Map<String, List<String>> userDataMap = {};


  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    getDetails(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final firstCurrentContext = context;
    Stream streams = FirebaseFirestore.instance.collection('reels').orderBy('dateTime', descending: true).snapshots();
    return SingleChildScrollView(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reels')
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
          return Center(
            child: Container(
              color: Colors.white,
              width: 525,
              height: 800,
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final document = snapshot.data!.docs[index];
                  String documentId = snapshot.data!.docs[index].id;
                  String postUserId = document['createdBy'];

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

                        User? user = FirebaseAuth.instance.currentUser;
                        String? userId = user?.uid;
                        List<String> likedBy = [];
                        int likes = 0;
                        bool isReel = true;
                        if (document['likes'] != null) {
                          likes = document['likes'];
                        }
                        return Column(
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ShowUserDetailsPage(
                                          userId: postUserId,
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
                                            profileImageUrl!,
                                            width: 30, // Increased width
                                            height: 30, // Increased height
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        firstName!,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        formattedTime,
                                        style: const TextStyle(fontSize: 14.0),
                                      ),
                                    ],
                                  ),
                                ),
                                Visibility(
                                  visible: currentUserIsViewingUser(postUserId),
                                  child: IconButton(
                                      onPressed: () {
                                        deletePost(documentId);
                                      },
                                      icon: const Icon(Icons.delete)),
                                ),
                              ],
                            ),
                            Text('Title: ${document['message']}'),
                            Stack(
                              children: [
                                VideoContainer(videoUrl: document['videoUrl']),
                                Positioned(
                                    top: 50,
                                    left: 400,
                                    child: Column(
                                      children: [
                                        StatefulBuilder(
                                          builder: (BuildContext context, StateSetter setState) {
                                            return Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 20,
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.thumb_up,
                                                          color: document['likedBy'].contains(userId) ? Colors.blue : Colors.white),
                                                      onPressed: () async {
                                                        if (document['likedBy'] == null) {
                                                          likedBy.add(userId!);
                                                          likes++;
                                                        } else if (document['likedBy'].contains(userId)) {
                                                          likedBy = List<String>.from(document['likedBy']);
                                                          likedBy.remove(userId);
                                                          likes = document['likes'];
                                                          likes--;
                                                        } else {
                                                          likedBy = List<String>.from(document['likedBy']);
                                                          likedBy.add(userId!);
                                                          likes = document['likes'];
                                                          likes++;
                                                        }
                                                        await FirebaseFirestore.instance.collection('reels').doc(documentId).update({
                                                          'likes': likes,
                                                          'likedBy': likedBy,
                                                        });
                                                      },
                                                    ),
                                                    Text('$likes', style: TextStyle(color: Colors.blue)),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        SizedBox(
                                          height: 40,
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.comment, color: Colors.white),
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return ReelsCommentInputSheet(
                                                      reelCreatorId: postUserId,
                                                      reelDocumentId: documentId,
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            // Text('Comments: ${document.commentsCount}'),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 40,
                                        ),
                                        Row(
                                          children: [
                                            // SizedBox(width: 40,),
                                            IconButton(
                                              icon: const Icon(Icons.share, color: Colors.white),
                                              onPressed: () async {
                                                int sharesCount=document['sharesCount']+1;
                                                await FirebaseFirestore.instance.collection('reels').doc(documentId).update({
                                                  'sharesCount': sharesCount,
                                                  // 'likedBy': document.likedBy,
                                                });
                                                final linkToShare = Uri.encodeComponent(document['videoUrl']);
                                                showModalBottomSheet(
                                                  context:firstCurrentContext,
                                                  builder: (BuildContext context) {
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
                                                              _showDialog(context, document['videoUrl']);
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

                                            Text('${document['sharesCount']}',style:TextStyle(color: Colors.blue),),
                                          ],
                                        ),
                                      ],
                                    ))
                              ],
                            ),
                          ],
                        );
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
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

  bool currentUserIsViewingUser(String postUserId) {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    if (currentUserId == postUserId) {
      return true;
    } else
      return false;
  }

  // void deletePost(String documentId) {}
  Future<void> deletePost(String documentId) async {
    try {
      // Access the collection and delete the document with the given ID
      await FirebaseFirestore.instance.collection('reels').doc(documentId).delete();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  // final whatsappLink = 'https://api.whatsapp.com/send?text=Check%20out%20this%20image:%20$encodedImageUrl';



  Future<void> _showDialog(BuildContext context, String linkToShare) async {
    final currentContext = context;
    List<String> userIds = [];

    showDialog(
      context: currentContext,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                ),
              ),
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
      },
    );
  }

  void shareLinkToAllFriends(List<String> userIds, String linkToShare) {
    for (String userId in userIds) {
      sendReelVideoUrl(userId, linkToShare);
    }
  }

  void sendReelVideoUrl(String userId,String videoLink) async {
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
    String? imageUrl = '';
    String text ="Check Out This Reel";
    String groupId = combineIds(currentUserId, userId);
    if (text.isNotEmpty) {
      await interactionsCollection.add({
        'interactedBy': currentUserId,
        'interactedWith': userId,
        'imageUrl': imageUrl,
        'dateTime': formattedDateTime,
        'message': text,
        'groupId': groupId,
        'videoUrl': videoLink,
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

}
