import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facebook/home/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Channels/creating_a_channel.dart';
import '../Channels/group_chat_widget.dart';
import '../base_page.dart';
import 'chat_widget.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? selectedUserDetailsDocumentId;
  Map<String, dynamic>? selectedUserDetailsDocumentData;
  String? groupId = "";
  late Future<QuerySnapshot<Map<String, dynamic>>> allUsersSnapshot;
  int count = 0;
  int counter = 0;
  int? value=0;

  Map<String, List<dynamic>> resultMap = {};
  bool isVanish = false;
  List<String> blockedList = [];
  List<String> groupUids = [];
  List<List<dynamic>> groupsInfo = [];
  late bool isGroup = false;
  String? clickedGroupId = "";
  List<dynamic> selectedGroupDocument = [];
  late String currentUserEmail = "";

  @override
  void initState() {
    setState(() {
      allUsersSnapshot = getUsers();
      getGroups();
      retrieveFieldValues();
      getBlockedList();
    });
    super.initState();
  }

  Future<void> getGroups() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    setState(() {
      groupUids = List<String>.from(documentSnapshot.data()?['groups']);
    });
    await getAllGroupInfo(groupUids);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUsers() async {
    try {
      return await FirebaseFirestore.instance.collection('users').get();
    } catch (e) {
      print('Error retrieving users: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Page'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(email: currentUserEmail)));
          },
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Center(
                child: Row(
                  children: [
                    Center(
                      child: Container(
                        height: 550,
                        width: 300,
                        decoration: customBoxDecoration,
                        margin: const EdgeInsets.all(10),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              margin: const EdgeInsets.all(10),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: const Text(
                                'Friends List',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 32,
                                ),
                              ),
                            ),
                            Expanded(
                              child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                future: allUsersSnapshot,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    final allUsersQuerySnapshot = snapshot.data;

                                    return ListView.builder(
                                      itemCount: allUsersQuerySnapshot!.docs.length,
                                      itemBuilder: (context, index) {
                                        String? key = allUsersQuerySnapshot.docs[index].id;
                                        User? user = FirebaseAuth.instance.currentUser;
                                        String? currentUserId = user?.uid;
                                        String? interactedTo = allUsersQuerySnapshot.docs[index].id;
                                        List? list1 = resultMap[interactedTo];
                                        value = list1?[0]??0;
                                        if (key == currentUserId) {
                                          return Container();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              String? interactedBy = currentUserId;
                                              String? interactedTo = allUsersQuerySnapshot.docs[index].id;
                                              List? list1 = resultMap[interactedTo];
                                              value = list1?[0]??0;
                                              updateOrAddInteraction(interactedBy!, interactedTo);
                                              groupId = createGroupId(allUsersQuerySnapshot.docs[index].id);
                                              selectedUserDetailsDocumentData = allUsersQuerySnapshot.docs[index].data();
                                              selectedUserDetailsDocumentId = allUsersQuerySnapshot.docs[index].id;
                                              deletedMessageCount(interactedBy, interactedTo);
                                              isVanish = list1![1];
                                              print("isVanish is $isVanish");
                                              resultMap[selectedUserDetailsDocumentId!] = [0, list1?[1]];
                                              isGroup = false;
                                              setState(() {
                                                interactedTo;
                                                interactedBy;
                                                value;
                                                groupId;
                                                selectedUserDetailsDocumentData;
                                                selectedUserDetailsDocumentId;
                                                isVanish;
                                                resultMap[selectedUserDetailsDocumentId!];
                                                isGroup;
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: Colors.blue,
                                              ),
                                              padding: const EdgeInsets.all(8),
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
                                                        allUsersQuerySnapshot.docs[index].data()['profileImageUrl'],
                                                        width: 30,
                                                        height: 30,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 20,
                                                  ),
                                                  Align(
                                                    alignment: Alignment.center,
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          allUsersQuerySnapshot.docs[index].data()['firstName'],
                                                          style: const TextStyle(fontSize: 26),
                                                        ),
                                                        SizedBox(
                                                          child: Visibility(
                                                            visible: !blockedList.contains(allUsersQuerySnapshot.docs[index].id) && value!>0,
                                                            child: Text("$value", style: const TextStyle(color: Colors.red)),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                            Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                margin: const EdgeInsets.all(10),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Groups List',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 32,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return CreateGroupDialog();
                                            },
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                )),
                            Expanded(
                              child: ListView.builder(
                                itemCount: groupsInfo.length,
                                itemBuilder: (context, index) {
                                  List<dynamic> groupData = groupsInfo[index];
                                  String name = groupData[0];
                                  String profileImageUrl = groupData[1];
                                  clickedGroupId = groupData[2]!;
                                  int unSeenCount = groupData[3];
                                  return Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        isGroup = true;
                                        setState(() {
                                          clickedGroupId;
                                          isGroup;
                                          selectedGroupDocument = groupData; // Update selectedGroupDocument
                                          groupData[3] = 0;
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.blue,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.blue,
                                                border: Border.all(
                                                  color: Colors.white,
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
                                            const SizedBox(width: 20),
                                            Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                name,
                                                style: const TextStyle(fontSize: 26),
                                              ),
                                            ),
                                            Visibility(
                                              visible:groupData[3]>0?true:false ,
                                                child: Text("(${groupData[3]})", style: const TextStyle(color: Colors.red))
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
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
            if (groupId == "" && clickedGroupId=="")
              const Padding(
                padding: EdgeInsets.fromLTRB(600, 0, 600, 0),
                child: Text("please select"),
              )
            else if (isGroup == false)
              Visibility(
                visible: !isGroup,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1100,
                    child: ChatWidget(
                      selectedUserDetailsDocumentData: selectedUserDetailsDocumentData,
                      selectedUserDetailsDocumentId: selectedUserDetailsDocumentId,
                      groupId: groupId,
                      isBlockedByYou: blockedList.contains(selectedUserDetailsDocumentId),
                      isVanish: isVanish,
                    ),
                  ),
                ),
              )
            else
              Visibility(
                visible: isGroup,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1100,
                    child: GroupChatWidget(
                      clickedGroupId: clickedGroupId,
                      selectedGroupDocument: selectedGroupDocument,
                    ),
                  ),
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
    if (currentUserId == selectedDocumentId) {
      return false;
    }
    return true;
  }

  createGroupId(String id) {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    setState(() {
      groupId;
    });
    return groupId = combineIds(id, currentUserId);

  }

  Future<void> updateOrAddInteraction(String interactedBy, String interactedTo) async {
    CollectionReference messageCount = FirebaseFirestore.instance.collection('messageCount');

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await messageCount
        .where('interactedBy', isEqualTo: interactedBy)
        .where('interactedTo', isEqualTo: interactedTo)
        .get() as QuerySnapshot<Map<String, dynamic>>;
    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot<Map<String, dynamic>> doc = querySnapshot.docs.first;
      count = doc['count'] ?? 0;
    } else {
      await messageCount.add({
        'interactedBy': interactedBy,
        'interactedTo': interactedTo,
        'count': 0,
      });
    }
  }

  Future<void> deletedMessageCount(String interactedBy, String interactedTo) async {
    CollectionReference<Map<String, dynamic>> messageCount = FirebaseFirestore.instance.collection('messageCount');
    QuerySnapshot<Object?> querySnapshot =
        await messageCount.where('interactedBy', isEqualTo: interactedTo).where('interactedTo', isEqualTo: interactedBy).get();
    for (QueryDocumentSnapshot<Object?> doc in querySnapshot.docs) {
      await messageCount.doc(doc.id).update({
        'count': 0,
      });
      setState(() {});
    }
  }

  void retrieveFieldValues() async {
    try {
      CollectionReference<Map<String, dynamic>> collectionRef = FirebaseFirestore.instance.collection('messageCount');
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await collectionRef.get();
      User? user = FirebaseAuth.instance.currentUser;
      String? currentUserId = user?.uid;
      for (QueryDocumentSnapshot<Map<String, dynamic>> document in querySnapshot.docs) {
        if (document.data()['interactedTo'] == currentUserId) {
          String uid = document.data()['interactedBy']; // Document UID
          int count = document.data()['count'];
          bool tempIsVanish = document.data()['isVanish']??false;
          resultMap[uid] = [count, tempIsVanish];
        }
      }
      setState(() {
        resultMap;
        print(resultMap);
      });
    } catch (e) {
      print('Error retrieving field values: $e');
      rethrow; // Rethrow the error to propagate it further if needed
    }
  }

  Future<void> getBlockedList() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;

    DocumentReference documentReference = FirebaseFirestore.instance.collection('users').doc(currentUserId);

    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await documentReference.get() as DocumentSnapshot<Map<String, dynamic>>;
    currentUserEmail = documentSnapshot.data()?['email'];
    blockedList = List<String>.from(documentSnapshot.data()!['blocked']);
  }

  Future<void> getAllGroupInfo(List<String> groupUids) async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    for (var group in groupUids) {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection('Groups').doc(group).get();
      if (documentSnapshot.exists) {
        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
        String name = data['groupName'];
        String profileImageUrl = data['groupProfileImageUrl'];
        String groupId = data['groupId'];
        int noOfUnseenMessages = data['messageCount'][currentUserId];
        List<dynamic> groupData = [name, profileImageUrl, groupId, noOfUnseenMessages];
        setState(() {
          groupsInfo.add(groupData);
        });
      } else {
        print('Document for group $group not found.');
      }
    }
  }
}
