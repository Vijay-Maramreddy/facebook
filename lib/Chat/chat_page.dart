
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String? groupId;
  late Future<QuerySnapshot<Map<String, dynamic>>> querySnapshot;
  int count=0;
  int counter=0;
  Map<String, int> resultMap= {};
  List<String> blockedList=[];
  // late List<String> friends=[];

  @override
  void initState() {
    setState(() {
      querySnapshot = getUsers();
      retrieveFieldValues();
      getBlockedList();

    });


    super.initState();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUsers() async {
    try {
      return await FirebaseFirestore.instance.collection('users').get();
    } catch (e) {
      print('Error retrieving users: $e');
      throw e; // Rethrow the error to propagate it further if needed
    }
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Page'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(

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
                                  child: const Text('Friends List',
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
                                    return const CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    final querySnapshot = snapshot.data;

                                    print(querySnapshot!.docs.length);
                                    return ListView.builder(
                                      itemCount: querySnapshot!.docs.length,
                                      itemBuilder: (context, index) {
                                        String? key=querySnapshot.docs[index].id;
                                        print("the key is $key");
                                        User? user = FirebaseAuth.instance.currentUser;
                                        String? currentUserId = user?.uid;
                                        if(key==currentUserId)
                                          {
                                            return Container();
                                          }
                                        int? value=resultMap[key];
                                        print("value for key $key is $value");

                                        return
                                          Column(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    User? user = FirebaseAuth.instance.currentUser;
                                                    String? currentUserId = user?.uid;
                                                    String? interactedBy = currentUserId;
                                                    String? interactedTo = querySnapshot.docs[index].id;
                                                    updateOrAddInteraction(interactedBy!, interactedTo!);
                                                    groupId=createGroupId(querySnapshot.docs[index].id);
                                                    selectedDocument = querySnapshot.docs[index].data();
                                                    selectedDocumentId = querySnapshot.docs[index].id;
                                                    deletedMessageCount(interactedBy!, interactedTo!);
                                                    resultMap[selectedDocumentId!]=0;
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
                                                            querySnapshot.docs[index].data()['profileImageUrl'],
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
                                                        querySnapshot.docs[index].data()['firstName'],
                                                        style: const TextStyle(fontSize: 26),
                                                      ),
                                                       SizedBox(
                                                         child:Visibility(
                                                           visible: !blockedList.contains(querySnapshot.docs[index].id),
                                                           child: Text("$value", style: TextStyle(color: Colors.red)),
                                                         ),
                                                       )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1100,
                child: ChatWidget(documentData: selectedDocument, documentId: selectedDocumentId,groupId:groupId,isBlocked:blockedList.contains(selectedDocumentId) ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  currentUserIsFriend(String? selectedDocumentId) {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;

    if(currentUserId==selectedDocumentId)
      {
        return false;
      }

    return true;
  }

  createGroupId(String id) {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    return groupId=combineIds(id,currentUserId);
  }

  Future<void> updateOrAddInteraction(String interactedBy, String interactedTo) async {

    CollectionReference messageCount = FirebaseFirestore.instance.collection('messageCount');

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await messageCount
        .where('interactedBy', isEqualTo: interactedBy)
        .where('interactedTo', isEqualTo: interactedTo)
        .get() as QuerySnapshot<Map<String, dynamic>>;
    if (querySnapshot.docs.isNotEmpty) {
      // Document exists, update count field
      DocumentSnapshot<Map<String, dynamic>> doc = querySnapshot.docs.first;
      count= doc['count'] ?? 0;
      // await doc.reference.update({'count': currentCount + 1});
    } else {
      // Document doesn't exist, create a new one
      await messageCount.add({
        'interactedBy': interactedBy,
        'interactedTo': interactedTo,
        'count': 0,
      });
    }
  }



  Future<void> deletedMessageCount(String interactedBy, String interactedTo) async {
    CollectionReference<Map<String, dynamic>> messageCount = FirebaseFirestore.instance.collection('messageCount');

    QuerySnapshot<Object?> querySnapshot = await messageCount
        .where('interactedBy', isEqualTo: interactedTo)
        .where('interactedTo', isEqualTo: interactedBy)
        .get();

    for (QueryDocumentSnapshot<Object?> doc in querySnapshot.docs) {
      // Update the 'count' field to 0
      await messageCount.doc(doc.id).update({
        'count': 0,
      });
      setState(() {

      });
      print('Count field updated to 0 for document with ID: ${doc.id}');
    }

  }


  void retrieveFieldValues() async {
    try {
      CollectionReference<Map<String, dynamic>> collectionRef = FirebaseFirestore.instance.collection('messageCount');
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await collectionRef.get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> document in querySnapshot.docs) {
        User? user = FirebaseAuth.instance.currentUser;
        String? currentUserId = user?.uid;
        // print(document.data());
        if(document.data()!['interactedTo']==currentUserId) {
          String uid =document.data()!['interactedBy'] ; // Document UID
          int fieldValue = document.data()!['count'];
          setState(() {
            resultMap[uid] = fieldValue;
          });
        }
      }
      print("resultMap is $resultMap");
      // return resultMap;
    } catch (e) {
      print('Error retrieving field values: $e');
      throw e; // Rethrow the error to propagate it further if needed
    }
  }

  Future<void> getBlockedList() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    DocumentReference documentReference =
    FirebaseFirestore.instance.collection('users').doc(currentUserId);
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await documentReference.get() as DocumentSnapshot<Map<String, dynamic>>;
    blockedList = List<String>.from(documentSnapshot.data()!['blocked']);
  }


}


