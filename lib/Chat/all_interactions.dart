import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:js_interop';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';
import '../reels/video_container.dart';

class AllInteractions extends StatefulWidget {
  late String? interactedBy;
  late String? interactedWith;
  late String? groupId;
  late List<String> oppositeBlocked;
  late bool youBlocked;
  late String? string;
  late String? media;
  AllInteractions({
    super.key,
    required this.interactedBy,
    required this.interactedWith,
    required this.groupId,
    required this.oppositeBlocked,
    required this.youBlocked,
    this.string = "",
    this.media = "",
  });

  @override
  State<AllInteractions> createState() => _AllInteractionsState();
}

class _AllInteractionsState extends State<AllInteractions> {
  final _scrollController = ScrollController();
  Map<String, List<String>> mapOfLists = {};
  String interactedByUserFirstName = "";
  String interactedWithUserFirstName = "";
  String interactedByUserProfileImageUrl = "assets/profilelogo.png";

  late DateTime startDate = DateTime.now();

  final AudioPlayer audioPlayer = AudioPlayer();
  Map<String, DateTime> seenBy = {};

  @override
  void initState() {
    super.initState();
    fetchMessengerDetails(widget.groupId);
    _scrollController.addListener(() {
      if (_isScrolledToBottom()) {
        print('Reached the end of the list');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();  // Dispose the controller when not needed
    super.dispose();
  }

  bool _isScrolledToBottom() {
    // Check if the current position is at the bottom of the list
    return (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200); // Adjust 200 as needed
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interactions')
          .where('groupId', isEqualTo: widget.groupId)
          .where('visibility', isEqualTo: true)
          .where('dateTime', isGreaterThanOrEqualTo: startDate) // Adjust this condition as needed
          .orderBy('dateTime',descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Show a loading indicator while data is loading
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data available.'));
        } else {
          return ListView.builder(
            reverse: true,
            controller: _scrollController,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String interactedByUserUid = data['interactedBy'];
              String interactedWithUserId = data['interactedWith'];
              List<String>? interactedByUserValues = mapOfLists[interactedByUserUid];
              Map<String, dynamic> seenByMap = data['seenBy'] ?? {};
              Map<String, DateTime> tempSeen = (seenByMap ?? {}).map(
                (key, value) => MapEntry(key, (value as Timestamp).toDate()),
              );
              if (interactedByUserValues != null) {
                interactedByUserFirstName = interactedByUserValues[0]; // First element is the first name
                interactedByUserProfileImageUrl = interactedByUserValues[1]; // Second element is the profile image URL
              } else {
                print('No values found for the user with UID: $interactedByUserUid');
              }
              List<String>? interactedWithUserValues = mapOfLists[interactedWithUserId];
              if (interactedWithUserValues != null) {
                interactedWithUserFirstName = interactedWithUserValues[0]; // First element is the first name
              } else {
                print('No values found for the user with UID: $interactedByUserUid');
              }
              User? user = FirebaseAuth.instance.currentUser;
              String? currentUserId = user?.uid;
              String msg1 = "";
              String msg2 = "";
              String msg3 = "";
              if (data['baseText'] != "") {
                if (data['interactedBy'] == currentUserId) {
                  msg1 = "you";
                  msg3 = data['baseText'];
                  msg2 = interactedWithUserFirstName;
                } else if (data['interactedWith'] == currentUserId) {
                  msg1 = interactedByUserFirstName;
                  msg3 = data['baseText'];
                  msg2 = "you";
                } else {
                  msg1 = interactedByUserFirstName;
                  msg3 = data['baseText'];
                  msg2 = interactedWithUserFirstName;
                }
              }
              return Visibility(
                visible: (widget.media == "")
                    ? (widget.string == "" || widget.string!.isEmpty || widget.string.isNull)
                        ? true
                        : data['message'].contains(widget.string)
                    : (widget.media == "images")
                        ? ((data['imageUrl'] == "") ? false : true)
                        : (data['videoUrl'] == "")
                            ? false
                            : true,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      if (data['baseText'] != "")
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: Colors.white60,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 0.1,
                                  ),
                                ),
                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                child: Text("$msg1 $msg3 $msg2")),
                            Text("${data['dateTime'].toDate()}"),
                            const SizedBox(
                              height: 20,
                            )
                          ],
                        )
                      else if (data['interactedBy'] == widget.interactedBy)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (data['audioUrl'] != "")
                                  AudioMessageWidget(audioUrl: data['audioUrl'], audioPlayer: audioPlayer)
                                else if (data['videoUrl'] != "" && data['videoUrl']!=null)
                                  SizedBox(
                                    child: buildVideoUrl(data['videoUrl'], data, tempSeen),
                                  )
                                else if (data['imageUrl'] == "" && data['videoUrl'] == "")
                                  if (data['message']!.startsWith('https://'))
                                    SizedBox(
                                      child: buildMessageUrl(data['message']),
                                    )
                                  else
                                    SizedBox(
                                      child: buildMessage(data['message']),
                                    )
                                else
                                  SizedBox(
                                    child: buildImage(data['imageUrl'], data['message']),
                                  ),
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ShowUserDetailsPage(
                                              userId: data['interactedBy'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.all(10.0),
                                        padding: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          border: Border.all(color: Colors.black),
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        height: 60,
                                        // width: 1400,
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
                                                  interactedByUserProfileImageUrl,
                                                  width: 30,
                                                  height: 30,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            Text(
                                              interactedByUserFirstName,
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Text("${data['dateTime'].toDate()}"),
                                  ],
                                ),
                                if (data['seenStatus'] == false)
                                  const Icon(Icons.check)
                                else
                                  const Row(
                                    children: [
                                      Icon(Icons.check, color: Colors.blue),
                                      Icon(Icons.check, color: Colors.blue),
                                    ],
                                  ),

                              ],
                            ),
                            buildSeenByWidget(tempSeen, mapOfLists),
                          ],
                        )
                      else if (data['interactedBy'] != widget.interactedBy)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ShowUserDetailsPage(
                                          userId: data['interactedBy'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(10.0),
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      border: Border.all(color: Colors.black),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),

                                    height: 60,
                                    // width: 1400,
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
                                              interactedByUserProfileImageUrl,
                                              width: 30,
                                              height: 30,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                        Text(
                                          interactedByUserFirstName,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Text("${data['dateTime'].toDate()}"),
                              ],
                            ),
                            if (data['audioUrl'] != "")
                              AudioMessageWidget(
                                audioUrl: data['audioUrl'],
                                audioPlayer: audioPlayer,
                              )
                            else if (data['videoUrl'] != "" && data['videoUrl']!=null)
                              SizedBox(
                                child: buildVideoUrl(data['videoUrl'], data, {}),
                              )
                            else if (data['imageUrl'] == "")
                              if (data['message']!.startsWith('https://'))
                                SizedBox(
                                  child: buildMessageUrl(data['message']),
                                )
                              else
                                SizedBox(
                                  child: buildMessage(data['message']),
                                )
                            else
                              SizedBox(
                                child: buildImage(data['imageUrl'], data['message']),
                              ),
                          ],
                        ),
                      if (widget.youBlocked)
                        if (index == (snapshot.data!.docs.length - 1))
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text("please click on below icon to Navigate to Details Page where you can unBlock the User"),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ShowUserDetailsPage(
                                        userId: widget.interactedWith,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.block),
                              )
                            ],
                          ),
                      if (widget.oppositeBlocked.contains(widget.interactedBy))
                        if (index == (snapshot.data!.docs.length - 1))
                          const Text("You have been blocked by the opposite person, messaging is not allowed"),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<void> fetchMessengerDetails(data) async {
    CollectionReference groupCollection = FirebaseFirestore.instance.collection('Groups');
    var userDocumentSnapshot = await groupCollection.doc(data).get();
    List<String> userMembers = [];
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;

    if (userDocumentSnapshot.exists) {
      updateSeenList();
      var userDocument = userDocumentSnapshot.data() as Map<String, dynamic>;
      String visibleDate = userDocument['visibleDate'];
      Map<String, DateTime> originalGroupMembers = {};
      LinkedHashMap<String, dynamic> linkedGroupMembers = userDocument['groupMembers'];
      linkedGroupMembers.forEach((key, value) {
        originalGroupMembers[key] = value.toDate();
      });
      DateTime? groupStarted = originalGroupMembers[currentUserId];
      if (visibleDate == "none") {
        startDate = groupStarted!;
      } else if (visibleDate == "1 week") {
        startDate = DateTime.now().subtract(const Duration(days: 7));
      } else if (visibleDate == "1 month") {
        startDate = DateTime.now().subtract(const Duration(days: 30));
      }
      if (userDocument['groupMembers'] != null) {
        Map<String, dynamic> groupMembersMap = userDocument['groupMembers'];
        userMembers = groupMembersMap.keys.toList();
        // userMembers = List<String>.from(userDocument['groupMembers']);
      }
      setState(() {
        startDate;
      });
    } else {
      userMembers = data.split('-');
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
      var userDocumentSnapshot = await usersCollection.doc(userMembers[0]).get();
      var userDocument = userDocumentSnapshot.data() as Map<String, dynamic>;
      // startDate=userDocument['dateTime'];
      startDate = userDocument['dateTime'].toDate();
    }
    setState(() {
      startDate;
    });
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

    for (String userMember in userMembers) {
      var userDocumentSnapshot = await usersCollection.doc(userMember).get();
      var userDocument = userDocumentSnapshot.data() as Map<String, dynamic>;
      List<String> user = [userDocument['firstName'], userDocument['profileImageUrl']];

      // Ensure the mapOfLists is initialized before updating it
      if (mapOfLists[userMember] == null) {
        mapOfLists[userMember] = [];
      }
      mapOfLists[userMember]!.addAll(user);
    }
    if (mounted) {
      setState(() {
        mapOfLists;
      });
    }
  }

  Future<void> updateSeenList() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('interactions')
        .where('groupId', isEqualTo: widget.groupId)
        .where('visibility', isEqualTo: true)
        .where('interactedBy',isNotEqualTo: currentUserId)
        .get();

    for (QueryDocumentSnapshot document in querySnapshot.docs) {
      Map<String, dynamic> seenByMap = document['seenBy'] ?? {};
      Map<String, DateTime> tempSeen = (seenByMap ?? {}).map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate()),
      );

      print(tempSeen.length);
      if (tempSeen.isEmpty) {
        tempSeen[currentUserId!] = DateTime.now();
        await FirebaseFirestore.instance.collection('interactions').doc(document.id).update({'seenBy': tempSeen});
      }
      if (!tempSeen.containsKey(currentUserId)) {
        tempSeen[currentUserId!] = DateTime.now();
        await FirebaseFirestore.instance.collection('interactions').doc(document.id).update({'seenBy': tempSeen});
      }
    }
  }

  Widget buildVideoUrl(String urlString, Map<String, dynamic> data, Map<String, DateTime> tempSeen) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(data['message'],style: const TextStyle(fontSize: 24,color: Colors.black87,fontWeight: FontWeight.w400)),
        ),
        Container(
          width: 550,
          height: 330,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: VideoContainer(
            // alignment: 'right',
            videoUrl: urlString,
          ),
        ),
      ],
    );
  }

  Widget buildMessageUrl(String message) {
    return Visibility(
      visible: message.startsWith('https://'),
      child: Column(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                window.open(message, '_blank');
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessage(String message) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(message,style: const TextStyle(fontSize: 24,color: Colors.black87,fontWeight: FontWeight.w400)),
        ),
      ],
    );
  }

  Widget buildImage(String imageUrl, String message) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Text(message,style: const TextStyle(fontSize: 24,color: Colors.black87,fontWeight: FontWeight.w400)),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Image.network(
            imageUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget buildSeenByWidget(Map<String, DateTime> tempSeen, Map<String, List<String>> mapOfLists) {
    int seenCount = tempSeen.length;
    int iterationCount = seenCount <= 3 ? seenCount : 3;
    int remainingCount = seenCount - iterationCount;

    List<Widget> seenWidgets = [];

    for (int i = 0; i < iterationCount; i++) {
      String key = tempSeen.keys.elementAt(i);
      String? imageUrl = mapOfLists[key]?[1] ?? "assets/profilelogo.png";
      DateTime? value = tempSeen[key];

      Widget container = Container(
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
            imageUrl,
            width: 30,
            height: 30,
            fit: BoxFit.cover,
          ),
        ),
      );

      seenWidgets.add(container);
    }

    seenWidgets.add(
      remainingCount > 0
          ? Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text('...and $remainingCount more'),
            )
          : const SizedBox.shrink(),
    );

    return Visibility(
      visible: seenCount>0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              showSeenUsersDialog(context, mapOfLists, tempSeen);
            },
            child: Text("Seen By ($seenCount):"),
          ),
          const SizedBox(width: 8.0),
          Row(
            children: seenWidgets,
          ),
          const SizedBox(width: 200,)
        ],
      ),
    );
  }

  void showSeenUsersDialog(BuildContext context, Map<String, List<String>> mapOfLists, Map<String, DateTime> tempSeen) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          alignment: Alignment.centerRight,
          title: const Text("Seen By"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: tempSeen.entries.map((entry) {
              String uid = entry.key;
              DateTime seenTime = entry.value;
              List<String> userData = mapOfLists[uid] ?? ['Unknown User', ''];
              String userName = userData[0];
              String userProfileImageUrl = userData[1];

              return ListTile(
                leading: ClipOval(
                  child: Image.network(
                    userProfileImageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(userName),
                subtitle: Text('Seen on: $seenTime'),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
