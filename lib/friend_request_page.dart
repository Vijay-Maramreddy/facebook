import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'base_page.dart';
import 'home/show_user_details_page.dart';

class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({super.key});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {
  FirebaseAuth auth = FirebaseAuth.instance;
  User? user;

  @override
  void initState() {
    user = auth.currentUser;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Friend Request Page", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('friendRequests')
              .where('requestedTo', isEqualTo: user?.uid)
              .where('friendStatus', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('No data available');
            }
            return Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              width: 400,
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final document = snapshot.data!.docs[index];
                  String documentId = snapshot.data!.docs[index].id;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(document['requestedBy'])
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text('User data not available');
                      }

                      DocumentSnapshot requesterInfo = snapshot.data!;
                      String profileImageUrl="";
                      if(requesterInfo['profileImageUrl']!=null)
                        {
                          profileImageUrl=requesterInfo['profileImageUrl'];
                        }
                      return SizedBox(
                        height: 80,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ShowUserDetailsPage(
                                          userId: document['requestedBy'],
                                        ),
                                  ),
                                );
                              },
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
                                        profileImageUrl,
                                        width: 30,
                                        height: 30,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    requesterInfo['firstName'],
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(onPressed: (){acceptRequest(requesterInfo.id);}, child: Text("Accept")),
                            ElevatedButton(onPressed: () {rejectRequest(requesterInfo.id);}, child: Text("Reject")),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> acceptRequest(String id) async {
    User? user = auth.currentUser;
    var requestedTo = user!.uid;
    var requestedBy = id;

    CollectionReference messages = FirebaseFirestore.instance.collection('messageCount');

    // Data to be added to the document
    Map<String, dynamic> data = {
      'count': 0,
      'interactedBy': requestedTo,
      'interactedTo': requestedBy,
      'isVanish': false,
    };

    // Add a new document with an auto-generated ID
    await messages.add(data);

    var requestId = createRequestId(requestedBy, requestedTo);
    CollectionReference friendRequests =
    FirebaseFirestore.instance.collection('friendRequests');

    friendRequests
        .where('requestId', isEqualTo: requestId)
        .get()
        .then((QuerySnapshot querySnapshot) {


      for (var document in querySnapshot.docs) {
        friendRequests.doc(document.id).delete().then((_) {


          print('Accepted request and deleted request: ${document.id}');


          DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(requestedTo);
          userDoc.get().then((DocumentSnapshot userSnapshot) {
            if (userSnapshot.exists) {
              List<String> friendsList = [];

              if (userSnapshot['friends'] is List) {
                friendsList = List.from(userSnapshot['friends']);
              }
              friendsList.add(requestedBy);

              userDoc.set({'friends': friendsList}, SetOptions(merge: true));
            } else {
              userDoc.set({'friends': [requestedBy]});
            }

          }).catchError((e) {
            print('Error getting user document: $e');
          });
          DocumentReference usersDoc = FirebaseFirestore.instance.collection('users').doc(requestedBy);
          usersDoc.get().then((DocumentSnapshot userSnapshot) {
            if (userSnapshot.exists) {
              List<String> friendsList = [];

              if (userSnapshot['friends'] is List) {
                friendsList = List.from(userSnapshot['friends']);
              }
              friendsList.add(requestedTo);

              usersDoc.set({'friends': friendsList}, SetOptions(merge: true));
            } else {
              usersDoc.set({'friends': [requestedTo]});
            }



          }).catchError((e) {
            print('Error getting user document: $e');
          });
        }

        ).catchError((e) {
          print('Error deleting friend request: $e');
        });
      }
    }
    ).catchError((e) {
      print('Error getting friend request documents: $e');
    });
  }


  String createRequestId(String requestedBy, String requestedTo) {
    return combineIds(requestedBy, requestedTo);
  }

  void rejectRequest(String id) {
    {
      User? user = auth.currentUser;
      var requestedTo = user!.uid;
      var requestedBy = id;
      var requestId = createRequestId(requestedBy, requestedTo);
      CollectionReference friendRequests =
      FirebaseFirestore.instance.collection('friendRequests');

      friendRequests
          .where('requestId', isEqualTo: requestId)
          .get()
          .then((QuerySnapshot querySnapshot) {


        querySnapshot.docs.forEach((QueryDocumentSnapshot document)
        {
          friendRequests.doc(document.id).delete().then((_) {


            print('Rejected request and deleted request: ${document.id}');

          }

          ).catchError((e) {
            print('Error deleting friend request: $e');
          });
        }

        );
      }
      ).catchError((e) {
        print('Error getting friend request documents: $e');
      });
    }
  }
}
