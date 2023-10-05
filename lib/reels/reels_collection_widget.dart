import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:facebook/Posts/comment_input_screen.dart';
import 'package:facebook/reels/reels_comment_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';
import 'dart:convert';
// import 'image_document_model.dart';

class ReelsCollectionWidget extends StatefulWidget {
  ReelsCollectionWidget();

  @override
  _ReelsCollectionWidgetState createState() => _ReelsCollectionWidgetState();
}

class _ReelsCollectionWidgetState extends State<ReelsCollectionWidget> {
  late String profileImageUrl = '';
  late String firstName = '';

  @override
  Widget build(BuildContext context) {
    Stream streams = FirebaseFirestore.instance
        .collection('reels')
        .orderBy('dateTime', descending: true)
        .snapshots();
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
            child: SizedBox(
              width: 800,
              height: 600,
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
                        final VideoPlayerController _videoPlayerController = VideoPlayerController.network(document['videoUrl']);
                        _videoPlayerController.initialize();
                        final ChewieController _chewieController = ChewieController(
                          videoPlayerController: _videoPlayerController,
                          aspectRatio: 16 / 9,
                          autoPlay: true,
                          looping: false,
                        );
                        User? user = FirebaseAuth.instance.currentUser;
                        String? userId = user?.uid;
                        List<String> likedBy=[];
                        int likes=0;
                        bool isReel=true;
                        if(document['likes']!=null)
                          {
                            likes=document['likes'];
                          }
                        print(likes);

                        return Container(
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
                                  ),
                                ],
                              ),
                              Text('Title: ${document['message']}'),

                              const SizedBox(height: 10.0),
                              SizedBox(
                                width: 500,
                                height: 400,
                                child: Chewie(controller: _chewieController),
                              ),
                              Row(
                                children: [
                                  StatefulBuilder(
                                    builder: (BuildContext context, StateSetter setState) {
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 200,
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.thumb_up, color: document['likedBy'].contains(userId)? Colors.blue : Colors.black),
                                                onPressed: () async {


                                                  if(document['likedBy']==null)
                                                  {
                                                    likedBy.add(userId!);
                                                    likes++;

                                                  }
                                                  else if(document['likedBy'].contains(userId))
                                                    {
                                                      likedBy = List<String>.from(document['likedBy']);
                                                      likedBy.remove(userId);
                                                      likes=document['likes'];
                                                      likes--;

                                                    }
                                                  else
                                                    {
                                                      likedBy=List<String>.from(document['likedBy']);
                                                      likedBy.add(userId!);
                                                      likes=document['likes'];
                                                      likes++;
                                                    }
                                                  await FirebaseFirestore.instance.collection('reels').doc(documentId).update({
                                                    'likes': likes,
                                                    'likedBy': likedBy,
                                                  });
                                                  setState((){
                                                  });

                                                },
                                              ),
                                              Text('Likes: $likes'),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(
                                    width: 130,
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.comment),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return ReelsCommentInputSheet(
                                                reelCreatorId:postUserId,reelDocumentId:documentId,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      // Text('Comments: ${document.commentsCount}'),
                                    ],
                                  ),
                                  SizedBox(
                                    width: 130,
                                  ),
                                  // IconButton(
                                  //   icon: Icon(Icons.emoji_emotions), // Emoji icon
                                  //   onPressed: () {
                                  //     openEmojiPicker(context); // Open the emoji picker modal bottom sheet
                                  //   },
                                  // ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () {},
                                      ),
                                      // Text('Shares: ${document.sharesCount}'),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),

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
    if(currentUserId==postUserId)
      {
        return true;
      }
    else
      return false;
  }

  // void deletePost(String documentId) {}
  Future<void> deletePost(String documentId) async {
    try {
      // Access the collection and delete the document with the given ID
      await FirebaseFirestore.instance.collection('reels').doc(documentId).delete();
      setState(() {});
    } catch (e) {
      print('Error deleting document: $e');
    }
  }
}


