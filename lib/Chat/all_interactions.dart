import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

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
          .where('groupId', isEqualTo:widget.groupId ) // Adjust this condition as needed
          .orderBy('dateTime', descending: false)
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
              print(data['message']);

              return Container(
                child: Column(
                  children: [
                    if (data['interactedBy'] == widget.interactedBy)
                      if(data['imageUrl']=="")
                          Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.all(16.0),
                            child: Text(data['message']),
                          )
                      else
                        Column(
                          children: [
                              Container(
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.fromLTRB(16, 16, 16,0),
                                  child: Image.network(
                                        data['imageUrl'],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        ),
                                  ),
                              Container(
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.fromLTRB(16,0,16, 16),
                                  child: Text(data['message']),
                                  )
                          ],
                        )
                    else
                      if(data['imageUrl']=="")
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.all(16.0),
                          child: Text(data['message']),
                        )
                      else
                        Row(
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.all(16.0),
                              child: Image.network(
                                data['imageUrl'],
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.all(16.0),
                              child: Text(data['message']),
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

// Stream<QuerySnapshot> mergeQueryResults() {
  //   Stream<QuerySnapshot> stream1 = FirebaseFirestore.instance
  //       .collection('interactions')
  //       .where('interactedWith', isEqualTo: widget.interactedWith)
  //       .where('interactedBy', isEqualTo: widget.interactedBy)
  //       .snapshots();
  //
  //   Stream<QuerySnapshot> stream2 = FirebaseFirestore.instance
  //       .collection('interactions')
  //       .where('interactedBy', isEqualTo: widget.interactedWith)
  //       .where('interactedWith', isEqualTo: widget.interactedBy)
  //       .snapshots();
  //
  //   // Add listeners to print the lengths of the streams
  //   stream1.listen((querySnapshot) {
  //     print('Stream 1 length: ${querySnapshot.docs.length}');
  //   });
  //
  //   stream2.listen((querySnapshot) {
  //     print('Stream 2 length: ${querySnapshot.docs.length}');
  //   });
  //
  //   return Rx.merge([stream1, stream2]);
  // }
}
