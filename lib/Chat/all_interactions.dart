import 'dart:async';
import 'dart:html';

import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:video_player/video_player.dart';

import '../base_page.dart';
import '../home/show_user_details_page.dart';
import '../reels/video_container.dart';

class AllInteractions extends StatefulWidget {
  late String? interactedBy;
  late String? interactedWith;
  late String? groupId;
  late List<String> oppositeBlocked;
  late bool youBlocked;
  AllInteractions(
      {super.key,
      required this.interactedBy,
      required this.interactedWith,
      required this.groupId,
      required this.oppositeBlocked,
      required this.youBlocked});

  @override
  State<AllInteractions> createState() => _AllInteractionsState();
}

class _AllInteractionsState extends State<AllInteractions> {
  Map<String, List<String>> mapOfLists = {};
  String firstName = "";
  String profileImageUrl = "https://www.freeiconspng.com/thumbs/profile-icon-png/am-a-19-year-old-multimedia-artist-student-from-manila--21.png";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchMessengerDetails(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interactions')
          .where('groupId', isEqualTo: widget.groupId)
          .where('visibility', isEqualTo: true) // Adjust this condition as needed
          .orderBy('dateTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // Show a loading indicator while data is loading
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No data available.'));
        } else {
          // Data is available, build your UI accordingly
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final messageText = data['message'];
              dynamic urlString = data['videoUrl'];
              String userUid = data['interactedBy'];
              List<String>? userValues = mapOfLists[userUid];
              if (userValues != null) {
                firstName = userValues[0]; // First element is the first name
                profileImageUrl = userValues[1]; // Second element is the profile image URL
              } else {
                print('No values found for the user with UID: $userUid');
              }
              // fetchMessengerDetails(data['interactedBy']);
              return Visibility(
                child: Column(
                  children: [
                    if (data['interactedBy'] == widget.interactedBy)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (urlString != "")
                            Column(children: [
                              Container(
                                width: 550,
                                height: 330,
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: VideoContainer(
                                  alignment: 'right',
                                  videoUrl: urlString,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: Text(data['message']),
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(data['dateTime']),
                              ),
                            ])
                          else if (data['imageUrl'] == "" && urlString == "")
                            if (data['message']!.startsWith('https://'))
                              Column(children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      window.open(data['message']!, '_blank');
                                    },
                                    child: Container(
                                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                      child: Text(
                                        data['message'],
                                        style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Text(data['dateTime']),
                                ),
                              ])
                            else
                              Column(children: [
                                Container(
                                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: Text(data['message']),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Text(data['dateTime']),
                                ),
                              ])
                          else
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: Image.network(
                                    data['imageUrl'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                                  child: Text(data['message']),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Text(data['dateTime']),
                                )
                              ],
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
                                        profileImageUrl ?? '',
                                        width: 30,
                                        height: 30,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text(
                                    firstName ?? '',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (data['interactedBy'] != widget.interactedBy)
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Row(
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
                                          profileImageUrl ?? '',
                                          width: 30,
                                          height: 30,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Text(
                                      firstName ?? '',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (urlString != "")
                              Column(children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 550,
                                  height: 330,
                                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: VideoContainer(
                                    alignment: 'left',
                                    videoUrl: urlString,
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: Text(data['message']),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Text(data['dateTime']),
                                ),
                              ])
                            else if (data['imageUrl'] == "")
                              if (data['message']!.startsWith('https://'))
                                Column(children: [
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        window.open(data['message']!, '_blank');
                                      },
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                        child: Text(
                                          data['message'],
                                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Text(data['dateTime']),
                                  ),
                                ])
                              else
                                Column(children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                    child: Text(data['message']),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Text(data['dateTime']),
                                  ),
                                ])
                            else
                              Column(
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                    child: Image.network(
                                      data['imageUrl'],
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                                    child: Text(data['message']),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Text(data['dateTime']),
                                  )
                                ],
                              ),
                          ],
                        ),
                      ),
                    if (widget.youBlocked)
                      if (index == (snapshot.data!.docs.length - 1))
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("You have blocked this User, please Unblock to interact to the User"),
                            Text("please click on below icon to Navigate to Details Page whre you can unBlock the User"),
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
                              icon: Icon(Icons.block),
                            )
                          ],
                        ),
                    if (widget.oppositeBlocked.contains(widget.interactedBy) && index == snapshot.data!.docs.length)
                      Text("You have been blocked by the opposite person, messaging is not allowed"),
                  ],
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

    if (userDocumentSnapshot.exists) {
      var userDocument = userDocumentSnapshot.data() as Map<String, dynamic>;
      if (userDocument['groupMembers'] != null) {
        userMembers = List<String>.from(userDocument['groupMembers']);
      }
    } else {
      userMembers = data.split('-');
    }
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
    setState(() {
      mapOfLists;
    });
  }
}
