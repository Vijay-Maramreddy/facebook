import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../app_style.dart';
import '../base_page.dart';

class CreateGroupDialog extends StatefulWidget {
  @override
  _CreateGroupDialogState createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  List<String> selectedFriends = [];
  String groupName = '';
  String groupDescription = '';
  late List<String> friendsUid;
  late List<List<String>> friendsData = [];
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    setState(() {
      fetchFriends();
    });
  }

  Future<void> fetchFriends() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    // Check if the document exists and contains the 'friends' key
    if (documentSnapshot.exists && documentSnapshot.data()?['friends'] != null) {
      friendsUid = List<String>.from(documentSnapshot.data()?['friends']);
    } else {
      print('User or friends not found.');
    }
    for (var friend in friendsUid) {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection('users').doc(friend).get();

      if (documentSnapshot.exists) {
        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
        String name = data['firstName'];
        String profileImageUrl = data['profileImageUrl'];

        // Add the extracted data to a list
        List<String> friendData = [friend, name, profileImageUrl];
        setState(() {
          friendsData.add(friendData);
        });
      } else {
        print('Document for friend $friend not found.');
      }
    }
  }

  Future<void> createGroup() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    List<String> admins = [currentUserId!];
    String uuid = AppStyles.uuid();
    selectedFriends.add(currentUserId);
    DateTime now = DateTime.now();
    String dateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);
    String imageUrl = '';
    if (_image != null) {
      imageUrl = await uploadImageToStorage('groupImage/' + uuid, _image!);
    }
    CollectionReference groupsCollection = FirebaseFirestore.instance.collection('Groups');
    String uid = AppStyles.uuid();
    Map<String, dynamic> groupData = {
      'groupName': groupName,
      'description': groupDescription,
      'groupProfileImageUrl': imageUrl,
      'admin': admins,
      'superAdmin':currentUserId,
      'createdBy':currentUserId,
      'groupMembers': selectedFriends,
      'groupId': uid,
      'dateTime': dateTime,
    };
    await groupsCollection.doc(uid).set(groupData);

    for (var friend in selectedFriends) {
      DocumentReference friendDocRef = FirebaseFirestore.instance.collection('users').doc(friend);

      DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await friendDocRef.get() as DocumentSnapshot<Map<String, dynamic>>;

      if (documentSnapshot.exists) {
        List<String> existingGroups = List<String>.from(documentSnapshot.data()?['groups'] ?? []);
        existingGroups.add(uid);

        await friendDocRef.update({'groups': existingGroups});
      } else {
        print('Document for friend $friend not found.');
      }
    }

    Navigator.pop(context);
  }

  Future<void> selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }
  // Function to handle creation of the group

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: selectImage,
                  child: Container(
                    width: 200, // Increased width
                    height: 200, // Increased height
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    child: _image != null
                        ? ClipOval(
                            child: Image.memory(
                            _image!,
                            width: 200, // Increased width
                            height: 200, // Increased height
                            fit: BoxFit.cover,
                          ))
                        : const Icon(
                            Icons.camera_alt,
                            size: 80, // Increased size
                            color: Colors.blue,
                          ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) => groupName = value,
                        decoration: InputDecoration(labelText: 'Group Name'),
                      ),
                      TextField(
                        onChanged: (value) => groupDescription = value,
                        decoration: InputDecoration(labelText: 'Group Description'),
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Column(
              children: friendsData.map((item) {
                return CheckboxListTile(
                  title: Row(
                    children: [
                      Container(
                        width: 30, // Increased width
                        height: 30, // Increased height
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue,
                            width: 0.1,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            item[2],
                            width: 30, // Increased width
                            height: 30, // Increased height
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(item[1]),
                    ],
                  ),
                  value: selectedFriends.contains(item[0]),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value != null) {
                        if (value) {
                          selectedFriends.add(item[0]);
                        } else {
                          selectedFriends.remove(item[0]);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: createGroup,
                  child: Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}
