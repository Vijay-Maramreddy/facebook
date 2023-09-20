import 'package:cloud_firestore/cloud_firestore.dart';

class ImageDocument {
  final String imageUrl;
  final String title;
  final String userId;
  final String profileImageUrl;
  final String firstName;
  final List<List<String>> comments;
  final List<String> likedBy;
  int likes;
  int commentsCount;
  int sharesCount;

  ImageDocument({
    required this.imageUrl,
    required this.title,
    required this.userId,
    required this.profileImageUrl,
    required this.firstName,
    required this.comments,
    required this.likedBy,
    this.likes = 0,
    this.commentsCount = 0,
    this.sharesCount=0,
  });
  factory ImageDocument.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return ImageDocument(
      imageUrl: data['imageUrl']?? '',
      title: data['title'] ?? '',
      userId: data['userId'] ?? '',
      comments: List<List<String>>.from(data['comments'] ?? []),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      likes: data['likes'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      profileImageUrl: data['profileImageUrl']??'',
      firstName:data['firstName']?? '',
    );
  }
  // void incrementLikes() {
  //   likes++;
  // }
}
