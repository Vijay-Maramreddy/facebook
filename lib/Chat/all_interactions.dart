import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';

typedef void StringCallback(String value);

class AllInteractions extends StatefulWidget {
  late String? interactedBy;
  late String? interactedWith;
  late String? groupId;
  late List<String> oppositeBlocked;
  late bool youBlocked;
  late String? string;
  late String? media;
  final StringCallback updateState;
  AllInteractions({
    super.key,
    required this.interactedBy,
    required this.interactedWith,
    required this.groupId,
    required this.oppositeBlocked,
    required this.youBlocked,
    this.string = "",
    this.media = "",
    required this.updateState,
  });

  @override
  State<AllInteractions> createState() => _AllInteractionsState();
}

class _AllInteractionsState extends State<AllInteractions> {
  Map<String, List<String>> mapOfLists = {};
  String interactedByUserFirstName = "";
  String interactedWithUserFirstName = "";
  String interactedByUserProfileImageUrl = "assets/profilelogo.png";
  late List<String> data2 = [];

  late DateTime startDate = DateTime.now();

  final AudioPlayer audioPlayer = AudioPlayer();
  Map<String, DateTime> seenBy = {};
  Map<String, List<String>> allReplyMessages = {};
  // StreamSubscription<QuerySnapshot>? chatSubscription;
  @override
  void initState() {
    super.initState();
    fetchMessengerDetails(widget.groupId);
    fetchAllReplyMessages();
    // setupChatListener();
  }

  // void setupChatListener() {
  //   chatSubscription = chatStream().listen((snapshot) {
  //     // Handle updates to chat messages
  //   });
  // }

  // Stream<QuerySnapshot> chatStream() {
  //   return FirebaseFirestore.instance
  //       .collection('interactions')
  //       .where('groupId', isEqualTo: widget.groupId)
  //       .where('visibility', isEqualTo: true)
  //       .where('dateTime', isGreaterThanOrEqualTo: startDate)
  //       .orderBy('dateTime', descending: true)
  //       .snapshots();
  // }

  // @override
  // void dispose() {
  //   chatSubscription?.cancel(); // Cancel the chat listener
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
      //   chatStream(),
      FirebaseFirestore.instance
          .collection('interactions')
          .where('groupId', isEqualTo: widget.groupId)
          .where('visibility', isEqualTo: true)
          .where('dateTime', isGreaterThanOrEqualTo: startDate)
          .orderBy('dateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data available.'));
        } else {
          return ListView.builder(
            reverse: true,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              String presentDocumentId = snapshot.data!.docs[index].id;
              Map<String, dynamic> data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String interactedByUserUid = data['interactedBy'];
              String interactedWithUserId = data['interactedWith'];
              List<String>? interactedByUserValues = mapOfLists[interactedByUserUid];
              Map<String, dynamic> seenByMap = data['seenBy'] ?? {};
              Map<String, DateTime> tempSeen = (seenByMap ?? {}).map(
                (key, value) => MapEntry(key, (value as Timestamp).toDate()),
              );
              if (allReplyMessages[presentDocumentId] != null) {
                data2 = allReplyMessages[presentDocumentId]!;
              }
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
              var alignment = MainAxisAlignment.center;
              if (currentUserId == data['interactedBy']) {
                alignment = MainAxisAlignment.end;
              } else {
                alignment = MainAxisAlignment.start;
              }
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
                  padding: const EdgeInsets.all(10),
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
                          mainAxisAlignment: alignment,
                          // crossAxisAlignment:  MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                if (details.localPosition.dx > MediaQuery.of(context).size.width / 4) {
                                  widget.updateState(presentDocumentId);
                                  setState(() {});
                                }
                              },
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: alignment,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.black),
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        child: Column(
                                          children: [
                                            if (allReplyMessages[presentDocumentId] != null)
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(width: 2),
                                                  color: Colors.white60,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: alignment,
                                                  children: [
                                                    Container(
                                                      color: Colors.blue,
                                                      child: Column(
                                                        children: [
                                                          Text("replied to ${data2[2] == interactedByUserFirstName ? "you" : data2[2]}",
                                                              style: const TextStyle(color: Colors.black)),
                                                          if (data2[0] != "")
                                                            AudioMessageWidget(audioUrl: data2[0], audioPlayer: audioPlayer)
                                                          else if (data2[3] != "")
                                                            SizedBox(
                                                              child: buildVideoUrl(data2[3], data),
                                                            )
                                                          else if (data2[1] != "")
                                                            if (data2[1].startsWith('https://'))
                                                              SizedBox(
                                                                child: buildMessageUrl(data2[1]),
                                                              )
                                                            else
                                                              SizedBox(
                                                                child: buildMessage(data2[1]),
                                                              )
                                                          else if (data2[4] != "")
                                                            SizedBox(
                                                              child: buildImage(data[4], data2[1]),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              Container(),
                                            Row(
                                              children: [
                                                if (data['audioUrl'] != "")
                                                  AudioMessageWidget(audioUrl: data['audioUrl'], audioPlayer: audioPlayer)
                                                else if (data['videoUrl'] != "" && data['videoUrl'] != null)
                                                  SizedBox(
                                                    child: buildVideoUrl(data['videoUrl'], data),
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
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
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
                                  Row(
                                    mainAxisAlignment: alignment,
                                    children: [
                                      Text(
                                        DateFormat('MM-dd HH:mm').format(data['dateTime'].toDate()),
                                      ),
                                      const SizedBox(
                                        width: 70,
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      buildSeenByWidget(tempSeen, mapOfLists),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        )
                      else if (data['interactedBy'] != widget.interactedBy)
                        Column(
                          mainAxisAlignment: alignment,
                          children: [
                            GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                if (details.localPosition.dx < MediaQuery.of(context).size.width / 4) {
                                  widget.updateState(presentDocumentId);
                                  setState(() {});
                                }
                              },
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: alignment,
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
                                      ),
                                      Container(
                                        margin: const EdgeInsets.all(10.0),
                                        // padding: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.black),
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        child: Column(
                                          children: [
                                            if (allReplyMessages[presentDocumentId] != null)
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(width: 2),
                                                  color: Colors.white60,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: alignment,
                                                  children: [
                                                    Container(
                                                      color: Colors.blue,
                                                      child: Column(
                                                        children: [
                                                          Text("replied to ${data2[2] == interactedByUserFirstName ? "you" : data2[2]}",
                                                              style: const TextStyle(color: Colors.black)),
                                                          if (data2[0] != "")
                                                            AudioMessageWidget(audioUrl: data2[0], audioPlayer: audioPlayer)
                                                          else if (data2[3] != "")
                                                            SizedBox(
                                                              child: buildVideoUrl(data2[3], data),
                                                            )
                                                          else if (data2[1] != "")
                                                            if (data2[1].startsWith('https://'))
                                                              SizedBox(
                                                                child: buildMessageUrl(data2[1]),
                                                              )
                                                            else
                                                              SizedBox(
                                                                child: buildMessage(data2[1]),
                                                              )
                                                          else if (data2[4] != "")
                                                            SizedBox(
                                                              child: buildImage(data[4], data2[1]),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              Container(),
                                            Row(
                                              children: [
                                                if (data['audioUrl'] != "")
                                                  AudioMessageWidget(audioUrl: data['audioUrl'], audioPlayer: audioPlayer)
                                                else if (data['videoUrl'] != "" && data['videoUrl'] != null)
                                                  SizedBox(
                                                    child: buildVideoUrl(data['videoUrl'], data),
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
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: alignment,
                                    children: [
                                      const SizedBox(
                                        width: 40,
                                      ),
                                      Text(
                                        DateFormat('MM-dd HH:mm').format(data['dateTime'].toDate()),
                                      ),
                                    ],
                                  ),
                                  // buildSeenByWidget(tempSeen, mapOfLists),
                                ],
                              ),
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
      startDate =  DateTime.now().subtract(const Duration(days: 365));
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

  Future<void> fetchAllReplyMessages() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('interactions').where('replyTo', isNotEqualTo: "").get();
    // List<String> fieldValues = [];
    for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
      Map<String, dynamic> data1 = documentSnapshot.data() as Map<String, dynamic>;
      String replyId = data1['replyTo'];
      DocumentSnapshot documentSnapshots = await FirebaseFirestore.instance.collection('interactions').doc(replyId).get();
      Map<String, dynamic> data = documentSnapshots.data() as Map<String, dynamic>;

      DocumentSnapshot documentSnapshot2 = await FirebaseFirestore.instance.collection('users').doc(data['interactedBy']).get();
      String name = documentSnapshot2['firstName'] ?? "";
      String imageUrl = data['imageUrl'] ?? "";
      String videoUrl = data['videoUrl'] ?? "";
      String audioUrl = data['audioUrl'] ?? "";
      String message = data['message'] ?? "";
      allReplyMessages[documentSnapshot.id] = [audioUrl, message, name, videoUrl, imageUrl];
    }
    if(mounted) {
      setState(() {
        allReplyMessages;
        // print(allReplyMessages);
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
        .where('interactedBy', isNotEqualTo: currentUserId)
        .get();

    for (QueryDocumentSnapshot document in querySnapshot.docs) {
      Map<String, dynamic> seenByMap = document['seenBy'] ?? {};
      Map<String, DateTime> tempSeen = (seenByMap ?? {}).map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate()),
      );
      if (document['dateTime'].toDate().isAfter(startDate) || document['baseText'] == "") {
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
      visible: seenCount > 0,
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
          const SizedBox(
            width: 200,
          )
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
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }


}
