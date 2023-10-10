import 'dart:async';
import 'dart:html';

import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:video_player/video_player.dart';

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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interactions')
          .where('groupId', isEqualTo: widget.groupId)
          .where('visibility',isEqualTo: true)// Adjust this condition as needed
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
            // reverse: true,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

              final messageText = data['message'];
              dynamic urlString=data['videoUrl'];

              return Visibility(
                visible: data['visibility'],
                child: Column(
                  children: [
                    if (data['interactedBy'] == widget.interactedBy)
                      if (urlString != "")
                        Column(
                            // mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                alignment: Alignment.topRight,
                                width: 550,
                                height: 330,
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: VideoContainer( alignment: 'right',videoUrl: urlString,),
                              ),
                              Container(
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: Text(data['message']),
                              ),
                              Container(
                                alignment: Alignment.centerRight,
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
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: Text(
                                    data['message'],
                                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(data['dateTime']),
                            ),
                          ])
                        else
                          Column(children: [
                            Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Text(data['message']),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(data['dateTime']),
                            ),
                          ])
                      else
                        Column(
                          children: [
                            Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Image.network(
                                data['imageUrl'],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: Text(data['message']),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(data['dateTime']),
                            )
                          ],
                        )
                    else if (urlString != "")
                      Column(children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          width: 550,
                          height: 330,
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: VideoContainer( alignment: 'left',videoUrl: urlString,),
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
                    if (widget.youBlocked)
                      if (index == (snapshot.data!.docs.length -1))
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
                                setState(() {});
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
}
