import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../base_page.dart';
import 'chat_widget.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? selectedDocumentId;
  Map<String, dynamic>? selectedDocument;
  late Future<QuerySnapshot<Map<String, dynamic>>> querySnapshot;

  @override
  void initState() {
    super.initState();
    querySnapshot = getUsers();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUsers() async {
    try {
      return await FirebaseFirestore.instance.collection('users').orderBy('dateTime', descending: true).get();
    } catch (e) {
      print('Error retrieving users: $e');
      throw e; // Rethrow the error to propagate it further if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    var document;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Page'),
      ),
      // backgroundColor: Colors.lightBlueAccent,
      body: Row(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Center(
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      height: 600,
                      width: 300,
                      decoration: customBoxDecoration,
                      margin: const EdgeInsets.all(10),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Column(
                        children: [
                          Container(
                            child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.blue,
                                ),
                                margin: const EdgeInsets.all(10),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                                child: Text('Friends List',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                    ))),
                          ),
                          Expanded(
                            child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              future: querySnapshot,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  final querySnapshot = snapshot.data;
                                  return ListView.builder(
                                    itemCount: querySnapshot!.docs.length,
                                    itemBuilder: (context, index) {
                                      document = querySnapshot.docs[index];
                                      return Column(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                selectedDocument = document.data() as Map<String, dynamic>;
                                                selectedDocumentId = querySnapshot.docs[index].id;
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(8),
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
                                                        document['profileImageUrl'],
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
                                                    document['firstName'],
                                                    style: TextStyle(fontSize: 26),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 10,
                                          )
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1100,
            child: ChatWidget(documentData: selectedDocument, documentId: selectedDocumentId),
          ),
        ],
      ),
    );
  }
}
