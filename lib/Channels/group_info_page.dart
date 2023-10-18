import 'dart:collection';
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

  late List<String> selectedFriends = [];
  late List<List<String>> friendsData = [];
  late String currentUserId="";

  String selectedDropdownValue = 'none'; // Default selected value

  List<String> dropdownOptions = ['none', '1 day', '1 week', '1 month'];

  List<String> admins = [];
  List<String> selectedAdmins = [];
  List<String> selectedGroupMembers = [];
  Map<String,DateTime> originalGroupMembers={};
  List<String> groupMembers = [];
  List<String> groupMembersAtStart = [];
  Map<String, List<String>> mapOfLists = {};
  String superAdmin = "";
  String createdBy = "";
  String createdUserId = "";
  late bool editable = false;
  Uint8List? _image;
  late String imageUrl;
  late String loadImageUrl = 'https://www.freeiconspng.com/thumbs/profile-icon-png/am-a-19-year-old-multimedia-artist-student-from-manila--21.png';
  DateTime formattedDateTime = DateTime.now();
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
            const SizedBox(height: 25,),
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
            Visibility(
              visible: superAdmin==currentUserId,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Select the Message Visibility"),
                  const SizedBox(width: 20,),
                  DropdownButton<String>(
                    value: selectedDropdownValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDropdownValue = newValue!;
                        handleDropdownSelection(selectedDropdownValue);
                      });
                    },
                    items: dropdownOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
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
                                    originalGroupMembers[groupMembers[index]]=DateTime.now();
                                    setState(() {
                                      selectedGroupMembers.add(groupMembers[index]);
                                    });
                                  } else {
                                    originalGroupMembers.remove(groupMembers[index]);
                                    setState(() {
                                      selectedGroupMembers.remove(groupMembers[index]);
                                    });
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
    currentUserId = user!.uid;
    String createdUserId = userDocument['createdBy'];
    CollectionReference createdUsersCollection = FirebaseFirestore.instance.collection('users');
    var createdUserDocument = await createdUsersCollection.doc(createdUserId).get();
    if (userDocument.exists) {
      setState(() {
        _groupNameController.text = userDocument['groupName'] ?? '';
        _descriptionController.text = userDocument['description'] ?? '';
        loadImageUrl = userDocument['groupProfileImageUrl'] ?? '';
        DateTime dateTime = userDocument['dateTime'].toDate();
        formattedDateTime = dateTime;
        createdUserId = userDocument['createdBy'];
        createdBy = createdUserDocument['firstName'];
        createdUserProfileImageUrl = createdUserDocument['profileImageUrl'];
        superAdmin = userDocument['superAdmin'];
        LinkedHashMap<String, dynamic> linkedGroupMembers = userDocument['groupMembers'];
        linkedGroupMembers.forEach((key, value) {
          originalGroupMembers[key] = value.toDate();
          groupMembers.add(key);
        });
        groupMembersAtStart=[...groupMembers];
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
      'groupMembers': originalGroupMembers,
    };

    String? message1 = "";
    List<String> tempGroupMembers = groupMembers;
    groupMembers.removeWhere((element) => originalGroupMembers.keys.contains(element));
    String message = "removed group members ";
    for (String members in tempGroupMembers) {
      message1 = mapOfLists[members]?[0];
      message = "$message $message1";
    }
    if (message1 != "") {
      sendMessageOrIcon(message);
    }

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

    List<String> tempSelectedAdmins = [...selectedAdmins];
    tempSelectedAdmins.removeWhere((element) => admins.contains(element));
    String? message3 = "";
    for (String members in tempSelectedAdmins) {
      message3 = mapOfLists[members]?[0];
      message = "promoted $message3 from general member to admin";
    }
    if (message3 != "") {
      sendMessageOrIcon(message);
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      // List<String> tempList=;
      DocumentReference documentReference = firestore.collection('Groups').doc(widget.groupId);
      await documentReference.update(updatedData);
      compareLists(groupMembers, originalGroupMembers.keys.toList());
      Navigator.pop(context);

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

    String msg="has Exited the group";
    sendMessageOrIcon(msg);

    DocumentReference groupDocRef = FirebaseFirestore.instance.collection('Groups').doc(widget.groupId);
    DocumentSnapshot groupDoc = await groupDocRef.get();
    if (groupDoc.exists) {
      Map<String,DateTime> originalList = groupDoc['groupMembers'];
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


  Future<void> fetchMessengerDetails(groupId) async {
    CollectionReference groupCollection = FirebaseFirestore.instance.collection('Groups');
    var userDocumentSnapshot = await groupCollection.doc(groupId).get();
    List<String> userMembers = [];
    if (userDocumentSnapshot.exists) {
      // userMembers=groupMembers;
      var userDocument = userDocumentSnapshot.data() as Map<String, dynamic>;
      if (userDocument['groupMembers'].keys != null) {
        userMembers = List<String>.from(userDocument['groupMembers'].keys);
      }
    } else {
      userMembers = groupId.split('-');
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
        function1(element);
      }
    }
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
    if (friendsData.isEmpty) {
      String message = "All your friends are already present in this group";
      showAlert(context, message);
    } else {
      final currentContext = context;
      showDialog(
        context: currentContext,
        builder: (context) {
          return Dialog(child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: friendsData.map((item) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
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
                          Checkbox(
                            value: isSelected(item),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value != null) {
                                  if (value) {
                                    originalGroupMembers[item[0]]=DateTime.now();
                                    selectedFriends.add(item[0]);
                                  } else {
                                    originalGroupMembers.remove(item[0]);
                                    selectedFriends.remove(item[0]);
                                  }
                                }
                              });
                            },
                          )
                        ],
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
                          addSelectedFriendsToGroup();
                          Navigator.pop(context);
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ));
        },
      );
    }
  }

  bool isSelected(List<String> item) {
    var result = selectedFriends.contains(item[0]);
    return result;
  }

  Future<void> fetchFriends() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? currentUserId = user?.uid;
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    // Check if the document exists and contains the 'friends' key
    List<String> friendsUidTemp = [];
    if (documentSnapshot.exists && documentSnapshot.data()?['friends'] != null) {
      friendsUidTemp = List<String>.from(documentSnapshot.data()?['friends']);
      removeElementsFromList1(friendsUidTemp, groupMembers);
    } else {
      print('User or friends not found.');
    }
    List<List<String>> friendsDataTemp = [];
    for (var friend in friendsUidTemp) {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection('users').doc(friend).get();

      if (documentSnapshot.exists) {
        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
        String name = data['firstName'];
        String profileImageUrl = data['profileImageUrl'];
        List<String> friendData = [friend, name, profileImageUrl];
        friendsDataTemp.add(friendData);
      } else {
        print('Document for friend $friend not found.');
      }
    }
    setState(() {
      friendsData.clear();
      friendsData.addAll(friendsDataTemp);
    });
  }

  void removeElementsFromList1(List<String> list1, List<String> list2) {
    list1.removeWhere((element) => list2.contains(element));
  }

  Future<void> addSelectedFriendsToGroup() async {
    DocumentReference groupDocRef = FirebaseFirestore.instance.collection('Groups').doc(widget.groupId);
    DocumentSnapshot groupDoc = await groupDocRef.get();

    List<String> gOriginalList = [];
    gOriginalList.addAll(groupMembersAtStart);
    for (String members in selectedFriends) {
      String addMessage = "added ";
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(members);
      DocumentSnapshot userDoc = await userDocRef.get();
      addMessage = "$addMessage ${userDoc['firstName']}";
      sendMessageOrIcon(addMessage);
      List<String> originalList = List<String>.from(userDoc['groups']);
      originalList.add(widget.groupId!);
      await userDocRef.update({'groups': originalList});
      gOriginalList.add(members);

    }
    await groupDocRef.update({'groupMembers': originalGroupMembers});

    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupId)
          .get();
      if (documentSnapshot.exists) {
        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
        Map<String, int> groupData = {};
        if (data['messageCount'] != null) {
          groupData = Map<String, int>.from(data['messageCount']);
        }
        for (String members in selectedFriends) {
          groupData[members] = 0;
        }
        await FirebaseFirestore.instance
            .collection('Groups')
            .doc(widget.groupId)
            .update({'messageCount': groupData});
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error: $e');
    }
    setState(() {
      selectedFriends.clear();
    });
  }

  void sendMessageOrIcon(String message) async {
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final CollectionReference interactionsCollection = FirebaseFirestore.instance.collection('interactions');
    String? imageUrl = '';
    if (message.isNotEmpty) {
      await interactionsCollection.add({
        'seenStatus':false,
        'interactedBy': currentUserId,
        'interactedWith': widget.groupId,
        'imageUrl': imageUrl,
        'dateTime': now,
        'message': "",
        'groupId': widget.groupId,
        'videoUrl': '',
        'visibility': true,
        'baseText': message,
        'seenBy':{},
      });
    }
  }

  void handleDropdownSelection(String selectedValue) {
    // Perform actions based on the selected value
    switch (selectedValue) {
      case 'none':
        break;
      case '1 day':
        break;
      case '1 week':
        break;
      case '1 month':
        break;
      default:
        break;
    }
  }

}
