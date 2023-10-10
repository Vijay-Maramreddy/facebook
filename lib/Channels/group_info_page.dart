// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// class GroupInfoPage extends StatefulWidget {
//   const GroupInfoPage({super.key, String? groupId});
//
//   @override
//   State<GroupInfoPage> createState() => _GroupInfoPageState();
// }
//
// class _GroupInfoPageState extends State<GroupInfoPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final TextEditingController _groupNameController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _groupProfileImageUrlController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Group Information"),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             GestureDetector(
//               onTap: selectImage,
//               child: Container(
//                 width: 200, // Increased width
//                 height: 200, // Increased height
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: Colors.blue,
//                     width: 2.0,
//                   ),
//                 ),
//                 child: _image != null
//                     ? ClipOval(
//                   child: Image.memory(
//                     _image!,
//                     width: 200, // Increased width
//                     height: 200, // Increased height
//                     fit: BoxFit.cover,
//                   ),
//                 )
//                     : loadImageUrl!.isNotEmpty
//                     ? ClipOval(
//                   child: Image.network(
//                     loadImageUrl!,
//                     width: 200,
//                     height: 200,
//                     fit: BoxFit.cover,
//                   ),
//                 )
//                     : const Icon(
//                   Icons.camera_alt,
//                   size: 80, // Increased size
//                   color: Colors.blue,
//                 ),
//               ),
//             ),
//             Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   TextFormField(
//                     enabled: editable,
//                     cursorColor: Colors.purple,
//                     controller: _groupNameController,
//                     decoration: InputDecoration(
//                       labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
//                       labelText: 'First Name',
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderSide: BorderSide.none,
//                         borderRadius: BorderRadius.circular(10.0),
//                       ),
//                       prefixIcon: const Icon(Icons.person, color: Colors.purple),
//                     ),
//                     validator: (value) {
//                       if (value!.isEmpty) {
//                         return 'Please enter your group name';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16.0),
//                   TextFormField(
//                     enabled: editable,
//                     cursorColor: Colors.purple,
//                     controller: _descriptionController,
//                     decoration: InputDecoration(
//                       labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
//                       labelText: 'Group Description',
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderSide: BorderSide.none,
//                         borderRadius: BorderRadius.circular(10.0),
//                       ),
//                       prefixIcon: const Icon(Icons.person, color: Colors.purple),
//                     ),
//                     validator: (value) {
//                       if (value!.isEmpty) {
//                         return 'Please enter the group Description';
//                       }
//                       return null;
//                     },
//                   ),
//
//                   Visibility(
//                     visible: !editable,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Visibility(
//                             visible: !(requestStatus || friendStatus),
//                             child: ElevatedButton(
//                                 onPressed: () {
//                                   sendFriendrequest();
//                                 },
//                                 child: Text("Send Friend Request"))),
//                         Visibility(
//                             visible: requestStatus && !friendStatus,
//                             child: Row(children: [
//                               const Text("Request Sent "),
//                               ElevatedButton(
//                                   onPressed: () {
//                                     cancelRequest();
//                                   },
//                                   child: Text("Cancel request"))
//                             ])),
//                         Visibility(
//                             visible: friendStatus,
//                             child: ElevatedButton(
//                                 onPressed: () {
//                                   removeFriend();
//                                 },
//                                 child: Text("Remove Friend")
//                             )
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 20,),
//                   Visibility(
//                       visible: !editable,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Visibility(
//                               visible: !isBlocked,
//                               child: ElevatedButton(
//                                 onPressed: () {
//                                   addToBlocked();
//                                 },
//                                 child: Text("Block"),
//                               )
//                           ),
//                           Visibility(
//                               visible: isBlocked,
//                               child: ElevatedButton(
//                                 onPressed: () {
//                                   removeFromBlocked();
//                                 },
//                                 child: Text("UnBlock"),
//                               )
//                           ),
//                         ],
//                       )
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
