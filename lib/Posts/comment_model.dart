import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../home/show_user_details_page.dart';

class Comment {
  String comment;
  String userId;
  String profileImageUrl;
  String firstName;
  String dateTime;

  Comment({
    required this.comment,
    required this.userId,
    required this.profileImageUrl,
    required this.firstName,
    required this.dateTime,
  });
}

class CommentWidget extends StatelessWidget {
  final Comment comment;
  CommentWidget(this.comment);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      margin: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowUserDetailsPage(
                          userId: comment.userId,
                        ),
                      ),
                    );
                  },
                  child: Row(
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
                            comment.profileImageUrl,
                            width: 30, // Increased width
                            height: 30, // Increased height
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(
                        comment.firstName,
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        comment.dateTime,
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            'Comment: ${comment.comment}',
            style: TextStyle(fontSize: 16.0),
          ),
        ],
      ),
    );
  }
}
