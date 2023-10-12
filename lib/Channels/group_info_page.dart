import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../app_style.dart';
import '../base_page.dart';
import '../home/show_user_details_page.dart';

class GroupInfoPage extends StatefulWidget {
  final String? groupId;
  const GroupInfoPage({super.key, this.groupId});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool makeAdminsVisible = false;
  bool makeAllMembersVisible = false;

  late List<String> friendsUid = [];
  late List<String> selectedFriends = [];
  late List<List<String>> friendsData = [];

  List<String> admins = [];
  List<String> selectedAdmins = [];
  List<String> selectedGroupMembers = [];
  List<String> userNameOfSelectedFriends = [];
  List<String> groupMembers = [];
  Map<String, List<String>> mapOfLists = {};
  String superAdmin = "";
  String createdBy = "";
  String createdUserId = "";
  late bool editable = false;
  Uint8List? _image;
  late String imageUrl;
  late String loadImageUrl = 'https://www.freeiconspng.com/thumbs/profile-icon-png/am-a-19-year-old-multimedia-artist-student-from-manila--21.png';
  String formattedDateTime = "";
  String createdUserProfileImageUrl =
      "https://www.freeiconspng.com/thumbs/profile-icon-png/am-a-19-year-old-multimedia-artist-student-from-manila--21.png";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadGroupDetails();
    fetchMessengerDetails(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Information"),
      ),
      body: SingleChildScrollView(
        child: Column(
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
                        ),
                      )
                    : loadImageUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              loadImageUrl,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 80, // Increased size
                            color: Colors.blue,
                          ),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowUserDetailsPage(
                          userId: createdUserId,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 50, // Increased width
                        height: 50, // Increased height
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue,
                            width: 0.1,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            createdUserProfileImageUrl,
                            width: 50, // Increased width
                            height: 50, // Increased height
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      Text(
                        "$createdBy   [createdBy]",
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text("Created on :$formattedDateTime"),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    enabled: editable,
                    cursorColor: Colors.purple,
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
                      labelText: 'Group Name',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      prefixIcon: const Icon(Icons.person, color: Colors.purple),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your group name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    enabled: editable,
                    cursorColor: Colors.purple,
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
                      labelText: 'Group Description',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      prefixIcon: const Icon(Icons.person, color: Colors.purple),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter the group Description';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                addMembersToGroup();
              },
              child: const Text("Add Members"),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  makeAdminsVisible = !makeAdminsVisible;
                });
              },
              child: const Text("Show All Admins"),
            ),
            const SizedBox(
              height: 20,
            ),
            Visibility(
              visible: makeAdminsVisible,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groupMembers.length,
                itemBuilder: (context, index) {
                  User? user = FirebaseAuth.instance.currentUser;
                  String? currentUserId = user?.uid;
                  final isAdminSuperAdmin = currentUserId == superAdmin;
                  final isChecked = selectedAdmins.contains(groupMembers[index]);
                  if (!isAdminSuperAdmin && !selectedAdmins.contains(groupMembers[index])) {
                    return Container();
                  } else {
                    return ListTile(
                      title: Row(
                        // mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShowUserDetailsPage(
                                    userId: groupMembers[index],
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 50, // Increased width
                                  height: 50, // Increased height
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 0.1,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      mapOfLists[groupMembers[index]]![1],
                                      width: 50, // Increased width
                                      height: 50, // Increased height
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 30,
                                ),
                                Text(
                                  mapOfLists[groupMembers[index]]![0],
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: isAdminSuperAdmin
                          ? Checkbox(
                              value: isChecked,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value != null) {
                                    if (value) {
                                      selectedAdmins.add(groupMembers[index]);
                                    } else {
                                      selectedAdmins.remove(groupMembers[index]);
                                    }
                                  }
                                });
                              },
                            )
                          : null,
                    );
                  }
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  makeAllMembersVisible = !makeAllMembersVisible;
                });
              },
              child: const Text("Show All Members"),
            ),
            const SizedBox(
              height: 20,
            ),
            Visibility(
              visible: makeAllMembersVisible,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groupMembers.length,
                itemBuilder: (context, index) {
                  User? user = FirebaseAuth.instance.currentUser;
                  String? currentUserId = user?.uid;
                  final isAdmin = admins.contains(currentUserId);
                  final isChecked = selectedGroupMembers.contains(groupMembers[index]);
                  return ListTile(
                    title: Row(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShowUserDetailsPage(
                                  userId: groupMembers[index],
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 50, // Increased width
                                height: 50, // Increased height
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 0.1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    mapOfLists[groupMembers[index]]![1],
                                    width: 50, // Increased width
                                    height: 50, // Increased height
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 30,
                              ),
                              Text(
                                mapOfLists[groupMembers[index]]![0],
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: isAdmin
                        ? Checkbox(
                            value: isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value != null) {
                                  if (value) {
                                    selectedGroupMembers.add(groupMembers[index]);
                                  } else {
                                    selectedGroupMembers.remove(groupMembers[index]);
                                  }
                                }
                              });
                            },
                          )
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Visibility(
              visible: editable,
              child: ElevatedButton(
                onPressed: () {
                  savedata();
                },
                child: const Text('save'),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                exitGroup();
              },
              child: const Text("Exit Group"),
            ),
          ],
        ),
      ),
    );
  }

  void loadGroupDetails() async {
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('Groups');
    var userDocument = await usersCollection.doc(widget.groupId).get();
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    String createdUserId = userDocument['createdBy'];
    CollectionReference createdUsersCollection = FirebaseFirestore.instance.collection('users');
    var createdUserDocument = await createdUsersCollection.doc(createdUserId).get();
    if (userDocument.exists) {
      setState(() {
        _groupNameController.text = userDocument['groupName'] ?? '';
        _descriptionController.text = userDocument['description'] ?? '';
        loadImageUrl = userDocument['groupProfileImageUrl'] ?? '';
        DateTime dateTime = DateTime.parse(userDocument['dateTime']);
        formattedDateTime = dateTime.toString();
        createdUserId = userDocument['createdBy'];
        createdBy = createdUserDocument['firstName'];
        createdUserProfileImageUrl = createdUserDocument['profileImageUrl'];
        superAdmin = userDocument['superAdmin'];
        groupMembers = List<String>.from(userDocument['groupMembers']);
        fetchFriends();
        admins = List<String>.from(userDocument['admin']);

        if (admins.contains(currentUserId)) {
          editable = true;
        }
        selectedAdmins = List<String>.from(admins);
        selectedGroupMembers = List<String>.from(groupMembers);
      });
    } else {
      String message = "user details not found";
      showAlert(context, message);
    }
  }

  Future<void> selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }

  void savedata() async {
    if (_image != null) {
      String uuid = AppStyles.uuid();
      imageUrl = await uploadImageToStorage('groupImage/$uuid', _image!);
    } else {
      imageUrl = loadImageUrl;
    }

    Map<String, dynamic> updatedData = {
      'groupName': _groupNameController.text,
      'description': _descriptionController.text,
      'groupProfileImageUrl': imageUrl,
      'admin': selectedAdmins,
      'groupMembers': selectedGroupMembers,
    };

    String? message1 = "";
    List<String> tempGroupMembers = groupMembers;
    groupMembers.removeWhere((element) => selectedGroupMembers.contains(element));
    String message = "removed group members ";
    for (String members in tempGroupMembers) {
      message1 = mapOfLists[members]?[0];
      message = "$message $message1";
    }
    if (message1 != "") {
      sendMessageOrIcon(message);
    }

    print("the admis are :$admins");
    // List<String> actualAdmins = admins;
    List<String> tempAdminsMembers = [...admins];
    String? message2 = "";
    tempAdminsMembers.removeWhere((element) => selectedAdmins.contains(element));
    for (String members in tempAdminsMembers) {
      message2 = mapOfLists[members]?[0];
      message = "demoted $message2 from admin to general member";
    }
    if (message2 != "") {
      sendMessageOrIcon(message);
    }

    List<String> tempAdminsMembers2 = [...admins];
    print("the admins are :$admins and selected admins are $selectedAdmins");
    selectedAdmins.removeWhere((element) => tempAdminsMembers2.contains(element));
    String? message3 = "";
    for (String members in selectedAdmins) {
      message3 = mapOfLists[members]?[0];
      message = "promoted $message3 from general member to admin";
    }
    if (message3 != "") {
      sendMessageOrIcon(message);
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String? id = widget.groupId;
      DocumentReference documentReference = firestore.collection('Groups').doc(widget.groupId);
      if (!documentReference.isNull) {
        await documentReference.update(updatedData);
        Navigator.pop(context);
      }
      compareLists(groupMembers, selectedGroupMembers);
    } catch (e) {
      print("Error updating user details: $e");
      String errorMessage = "An error occurred while updating user details";
      showAlert(context, errorMessage);
    }
  }

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> exitGroup() async {
    String? id = widget.groupId;
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    DocumentReference groupDocRef = FirebaseFirestore.instance.collection('Groups').doc(widget.groupId);
    DocumentSnapshot groupDoc = await groupDocRef.get();
    if (groupDoc.exists) {
      List<String> originalList = List<String>.from(groupDoc['groupMembers']);
      originalList.remove(currentUserId);
      await groupDocRef.update({'groupMembers': originalList});
    } else {
      print('Document not found for UID: $id');
    }

    DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
    DocumentSnapshot userDoc = await userDocRef.get();
    if (groupDoc.exists) {
      List<String> originalList = List<String>.from(userDoc['groups']);
      originalList.remove(id);
      await userDocRef.update({'groups': originalList});
    } else {
      print('Document not found for UID: $currentUserId');
    }
    Navigator.pop(context);
  }

  Future<void> fetchMessengerDetails(data) async {
    CollectionReference groupCollection = FirebaseFirestore.instance.collection('Groups');
    var userDocumentSnapshot = await groupCollection.doc(data).get();
    List<String> userMembers = [];
    if (userDocumentSnapshot.exists) {
      var userDocument = userDocumentSnapshot.data() as Map<String, dynamic>;
      if (userDocument['groupMembers'] != null) {
        userMembers = List<String>.from(userDocument['groupMembers']);
      }
    } else {
      userMembers = data.split('-');
    }
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
    for (String userMember in userMembers) {
      var userDocumentSnapshot = await usersCollection.doc(userMember).get();
      var userDocument = userDocumentSnapshot.data() as Map<String, dynamic>;
      List<String> user = [userDocument['firstName'], userDocument['profileImageUrl']];
      if (mapOfLists[userMember] == null) {
        mapOfLists[userMember] = [];
      }
      mapOfLists[userMember]!.addAll(user);
    }
    setState(() {
      mapOfLists;
    });
  }

  void compareLists(List<String> list1, List<String> list2) {
    for (String element in list1) {
      if (!list2.contains(element)) {
        // Call function1 with the element
        function1(element);
      }
    }
    // for (String element in list2) {
    //   if (!list1.contains(element)) {
    //     function2(element);
    //   }
    // }
  }

  Future<void> function1(String element) async {
    DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(element);
    DocumentSnapshot userDoc = await userDocRef.get();
    List<String> originalList = List<String>.from(userDoc['groups']);
    originalList.remove(widget.groupId);
    await userDocRef.update({'groups': originalList});
  }

  Future<void> function2(String element) async {
    DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(element);
    DocumentSnapshot userDoc = await userDocRef.get();
    List<String> originalList = List<String>.from(userDoc['groups']);
    originalList.add(widget.groupId!);
    await userDocRef.update({'groups': originalList});
  }

  void addMembersToGroup() {
    if (friendsUid.isEmpty) {
      String message = "All your friends are already present in this group";
      showAlert(context, message);
    } else {
      final currentContext = context;
      showDialog(
        context: currentContext,
        builder: (context) {
          return Dialog(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: friendsData.map((item) {
                    return CheckboxListTile(
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                item[2],
                                width: 30,
                                height: 30,
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(currentContext);
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedFriends;
                        });
                        addSelectedFriendsToGroup();
                        Navigator.pop(context);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> fetchFriends() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    // Check if the document exists and contains the 'friends' key
    if (documentSnapshot.exists && documentSnapshot.data()?['friends'] != null) {
      friendsUid = List<String>.from(documentSnapshot.data()?['friends']);
      removeElementsFromList1(friendsUid, groupMembers);
      setState(() {
        friendsUid;
      });
    } else {
      print('User or friends not found.');
    }
    for (var friend in friendsUid) {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection('users').doc(friend).get();

      if (documentSnapshot.exists) {
        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
        String name = data['firstName'];
        String profileImageUrl = data['profileImageUrl'];
        List<String> friendData = [friend, name, profileImageUrl];
        setState(() {
          friendsData.add(friendData);
          print(friendsData);
        });
      } else {
        print('Document for friend $friend not found.');
      }
    }
  }

  void removeElementsFromList1(List<String> list1, List<String> list2) {
    setState(() {
      list1.removeWhere((element) => list2.contains(element));
    });
  }

  Future<void> addSelectedFriendsToGroup() async {
    DocumentReference groupDocRef = FirebaseFirestore.instance.collection('Groups').doc(widget.groupId);
    DocumentSnapshot groupDoc = await groupDocRef.get();
    String message = "added ";
    for (String members in selectedFriends) {
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(members);
      DocumentSnapshot userDoc = await userDocRef.get();
      userNameOfSelectedFriends.add(userDoc['firstName']);
      String message2 = userDoc['firstName'];
      message = "$message $message2";
      List<String> originalList = List<String>.from(userDoc['groups']);
      originalList.add(widget.groupId!);
      await userDocRef.update({'groups': originalList});
      List<String> gOriginalList = List<String>.from(groupDoc['groupMembers']);
      gOriginalList.add(members);
      await groupDocRef.update({'groupMembers': gOriginalList});
      setState(() {
        fetchFriends();
      });
    }
    sendMessageOrIcon(message);
  }

  void sendMessageOrIcon(String message) async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    String? imageUrl = '';
    // String groupId = combineIds(currentUserId, widget.groupId);
    if (message.isNotEmpty) {
      await interactionsCollection.add({
        'interactedBy': currentUserId,
        'interactedWith': widget.groupId,
        'imageUrl': imageUrl,
        'dateTime': formattedDateTime,
        'message': "",
        'groupId': widget.groupId,
        'videoUrl': '',
        'visibility': true,
        'baseText': message,
      });
    }
  }
}
