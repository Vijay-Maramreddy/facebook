import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class AllInteractions extends StatefulWidget {
  late String? interactedBy;
  late String? interactedWith;
  AllInteractions({super.key, required this.interactedBy, required this.interactedWith});

  @override
  State<AllInteractions> createState() => _AllInteractionsState();
}

class _AllInteractionsState extends State<AllInteractions> {
  // String interactedBy=widget.interactedBy;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
          child: StreamBuilder<QuerySnapshot>(
            stream: mergeQueryResults(),
            // stream: FirebaseFirestore.instance
            //     .collection('interactions')
            //     // .where('dateTime', isGreaterThanOrEqualTo: DateTime.now()) // Adjust this condition as needed
            //     .where('interactedBy', whereIn: [widget.interactedBy, widget.interactedWith])
            //     .where('interactedWith', whereIn: [widget.interactedBy, widget.interactedWith])
            //     .orderBy('dateTime', descending: false)
            //     .snapshots(),
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

                    // Example: Displaying the message
                    return ListTile(
                      title: Text(data['message']),
                    );
                  },
                );
              }
            },
          )

    );
  }
  // import 'package:rxdart/rxdart.dart';

  Stream<QuerySnapshot> mergeQueryResults() {
    StreamController<QuerySnapshot> controller =
    StreamController<QuerySnapshot>.broadcast();

    Stream<QuerySnapshot> stream1 = FirebaseFirestore.instance
        .collection('interactions')
        .where('dateTime', isGreaterThanOrEqualTo: DateTime.now())
        .where('interactedBy', isEqualTo: widget.interactedBy)
        .snapshots();

    Stream<QuerySnapshot> stream2 = FirebaseFirestore.instance
        .collection('interactions')
        .where('dateTime', isGreaterThanOrEqualTo: DateTime.now())
        .where('interactedWith', isEqualTo: widget.interactedWith)
        .snapshots();

    stream1.listen((event) {
      controller.add(event);
    });

    stream2.listen((event) {
      controller.add(event);
    });

    return controller.stream;
  }



}
