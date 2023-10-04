import 'dart:async';
import 'dart:html';

import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:video_player/video_player.dart';

class AllInteractions extends StatefulWidget {
  late String? interactedBy;
  late String? interactedWith;
  late String? groupId;
  AllInteractions({super.key, required this.interactedBy, required this.interactedWith, required this.groupId});

  @override
  State<AllInteractions> createState() => _AllInteractionsState();
}

class _AllInteractionsState extends State<AllInteractions> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interactions')
          .where('groupId', isEqualTo: widget.groupId) // Adjust this condition as needed
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
              print(data['message']);
              final messageText = data['message'];

              final VideoPlayerController videoPlayerController = VideoPlayerController.network(data['videoUrl']);
              final ChewieController chewieController = ChewieController(
                videoPlayerController: videoPlayerController,
                aspectRatio: 16 / 9, // Adjust the aspect ratio as needed
                autoPlay: true,
                looping: true,
              );
              return Container(
                child: Column(
                  children: [
                    if (data['interactedBy'] == widget.interactedBy)
                      if(data['videoUrl']!="")
                        Column(
                          // mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                            Container(
                                alignment: Alignment.topRight,
                                width: 400,
                                height: 200,
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: Chewie(controller: chewieController),
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
                          ]
                        )
                      else if(data['imageUrl'] == "" && data['videoUrl']=="")
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
                    else
                      if(data['videoUrl']!="")
                        Column(
                            children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                width: 400,
                                height: 200,
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: Chewie(controller: chewieController),
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
                            ]
                        )
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
                      )
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }

  Stream<QuerySnapshot> mergeQueryResults() {
    StreamController<QuerySnapshot> controller = StreamController<QuerySnapshot>.broadcast();

    Stream<QuerySnapshot> stream1 = FirebaseFirestore.instance
        .collection('interactions')
        .where('interactedWith', isEqualTo: widget.interactedWith)
        .where('interactedBy', isEqualTo: widget.interactedBy)
        .snapshots();

    Stream<QuerySnapshot> stream2 = FirebaseFirestore.instance
        .collection('interactions')
        .where('interactedBy', isEqualTo: widget.interactedWith)
        .where('interactedWith', isEqualTo: widget.interactedBy)
        .snapshots();

    // Listen to stream1 and add the data to the controller
    stream1.listen((snapshot) {
      print('Stream 1 length: ${snapshot.docs.length}');
      controller.add(snapshot);
    });

    // Listen to stream2 and add the data to the controller
    stream2.listen((snapshot) {
      print('Stream 2 length: ${snapshot.docs.length}');
      controller.add(snapshot);
    });

    // Listen to the controller's stream to print its length before returning
    controller.stream.listen((mergedSnapshot) {
      print('Merged stream length: ${mergedSnapshot.docs.length}');
    });

    return controller.stream;
  }
}
