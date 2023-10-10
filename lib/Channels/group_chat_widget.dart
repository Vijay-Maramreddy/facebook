import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GroupChatWidget extends StatefulWidget {
  final String? clickedGroupId;
  const GroupChatWidget({super.key, required this.clickedGroupId});

  @override
  State<GroupChatWidget> createState() => _GroupChatWidgetState();
}

class _GroupChatWidgetState extends State<GroupChatWidget> {
  late String groupName = '';
  late String groupDescription = '';
  late List<String> groupMembers = [];
  late String groupProfileImageUrl = '';

  @override
  void initState() {
    String? id = widget.clickedGroupId;
    if (id != null && id.isNotEmpty) {
      print("the group id is $id");
      getGroupData(id);
    } else {
      print("Invalid group id: $id");
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => ShowUserDetailsPage(
              //       userId: widget.documentId,
              //     ),
              //   ),
              // );
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
                        groupProfileImageUrl,
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
                    groupName ?? '',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getGroupData(String clickedGroupId) async {
    print(clickedGroupId);
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection('Groups').doc(clickedGroupId).get();
    setState(() {
      groupName = documentSnapshot.data()!['groupName'];
      groupDescription = documentSnapshot.data()!['description'];
      groupProfileImageUrl = documentSnapshot.data()!['groupProfileImageUrl'];
      groupMembers = documentSnapshot.data()!['groupMembers'];
      print(groupName);
    });
  }
}
