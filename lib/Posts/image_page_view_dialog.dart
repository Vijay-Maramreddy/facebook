import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../base_page.dart';
import 'comment_input_screen.dart';
import 'image_document_model.dart';

class ImagePageViewDialog extends StatefulWidget {
  final QuerySnapshot querySnapshot;
  final int initialIndex;

  const ImagePageViewDialog({super.key, required this.querySnapshot, required this.initialIndex});

  @override
  _ImagePageViewDialogState createState() => _ImagePageViewDialogState();
}

class _ImagePageViewDialogState extends State<ImagePageViewDialog> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _pageController;
  final GlobalKey _pageViewKey = GlobalKey();
  late int _currentIndex = 0;
  Timer? _timer;

  _ImagePageViewDialogState() {
    _pageController = PageController(initialPage: 0);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_currentIndex < widget.querySnapshot.docs.length - 1) {
        _pageController.animateToPage(_currentIndex + 1, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();

    // Cancel the timer when the widget is disposed
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;
    return Dialog(
      child: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          // Display the PageView and navigation arrows here
          SizedBox(
            height: 600,
            width: 600, // Specify the height as needed
            child: Stack(
              children: [
                PageView.builder(
                  key: _pageViewKey,
                  itemCount: widget.querySnapshot.docs.length,
                  controller: _pageController, // Use _pageController here
                  itemBuilder: (context, index) {
                    final DocumentSnapshot document = widget.querySnapshot.docs[index];
                    User? user = FirebaseAuth.instance.currentUser;
                    late bool alreadyLiked = (document['likedBy'].contains(user?.uid));
                    bool currentUserIsViewingUser = false;
                    if (document['userId'] == user?.uid) {
                      currentUserIsViewingUser = true;
                    }
                    return Column(children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Visibility(
                        visible: currentUserIsViewingUser,
                        child: IconButton(
                          onPressed: () {
                            deletePost(document.id);
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ),
                      Text(
                        'Title: ${document['title']}',
                        style: const TextStyle(fontSize: 40, color: Colors.blue),
                      ),
                      GestureDetector(
                        onDoubleTap: () async {
                          DocumentSnapshot imageSnapshot = await FirebaseFirestore.instance.collection('images').doc(document.id).get();
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
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            document['imageUrl'],
                            width: 400,
                            height: 400,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.thumb_up, color: alreadyLiked ? Colors.blue : Colors.black),
                                    onPressed: () async {
                                      DocumentSnapshot imageSnapshot = await FirebaseFirestore.instance.collection('images').doc(document.id).get();
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
                                  Visibility(
                                    visible: isCountVisible(document['userId']),
                                    child: Text('Likes: ${document['likes']}'),
                                  ),
                                ],
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
                                            documentsId: document.id,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Visibility(
                                    visible: isCountVisible(document['userId']),
                                    child: Text('Comments: ${document['commentsCount']}'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ]);
                  },
                  onPageChanged: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                    // widget.onIndexChanged?.call(index);
                  },
                ),
                Positioned(
                  top: 300,
                  left: 0,
                  child: IconButton(
                    onPressed: () {
                        if (_currentIndex > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                          );
                        }
                    },
                    icon: Visibility(
                      visible: _currentIndex > 0,
                        child: const Icon(Icons.arrow_back)
                    ),
                  ),
                ),
                Positioned(
                  top: 300,
                  right: 0,
                  child: IconButton(
                    onPressed: () {
                      if (_currentIndex < widget.querySnapshot.docs.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    icon: Visibility(
                      visible: _currentIndex < widget.querySnapshot.docs.length - 1,
                        child: const Icon(Icons.arrow_forward)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  void incrementLike(ImageDocument document, String? userId, documentId) async {
    document.likes++;
    document.likedBy.add(userId!);
    FirebaseFirestore.instance.collection('images').doc(documentId).update({
      'likes': document.likes,
      'likedBy': document.likedBy,
    });
    String groupId = combineIds(userId, document.userId);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    String message = "liked the status";
    await interactionsCollection.add({
      'interactedBy': userId,
      'interactedWith': document.userId,
      'imageUrl': document.imageUrl,
      'dateTime': DateTime.now(),
      'message': message,
      'groupId': groupId,
      'seenStatus': false,
      'baseText': "",
      'videoUrl': '',
      'audioUrl': '',
      'visibility': true,
      'seenBy': {},
      'isVanish': false,
    });
  }

  isCountVisible(String userId) {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    if (currentUserId == userId) {
      return true;
    }
    return false;
  }

  Future<void> deletePost(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('images').doc(documentId).delete();
      Navigator.pop(_scaffoldKey.currentContext!);
    } catch (e) {
      print('Error deleting document: $e');
    }
  }
}
