import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ImageDocumentModel.dart';

class ImageCollectionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('images').snapshots(),
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

          // Process the retrieved documents and display them
          return Container(
            width: 600,
            height: 400,
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final document = snapshot.data!.docs[index];
                return buildImageCard(
                  ImageDocument(
                    imageUrl: document['imageUrl'],
                    title: document['title'],
                    userId: document['userId'],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildImageCard(ImageDocument document) {
    // Check if the fields exist in the document
    bool hasImageUrl = document.imageUrl != null && document.imageUrl.isNotEmpty;
    bool hasTitle = document.title != null && document.title.isNotEmpty;
    bool hasUid = document.userId != null && document.userId.isNotEmpty;

    return Container(
      margin: EdgeInsets.all(10.0),
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: [
          if (hasUid)
            Text('UserID: ${document.userId}'),
          SizedBox(height: 10.0),
          if (hasTitle)
            Text('Title: ${document.title}'),
          SizedBox(height: 5.0),
          if (hasImageUrl)
            Image.network(
              document.imageUrl,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
        ],
      ),
    );
  }

}
