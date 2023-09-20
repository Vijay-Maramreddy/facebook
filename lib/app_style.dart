import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

class AppStyles {
  static const Color buttonColor = Color.fromARGB(255, 255, 217, 0);
  static const Color textColor = Color.fromARGB(255, 0, 0, 55);
  static const Color whiteColor = Colors.white;
  static const Color drawerColor = Color.fromARGB(255, 34, 34, 36);
  static const Color drawerIconColor = Colors.white;
  static const Color appBarColor = Color.fromARGB(255, 60, 60, 60);
  static const Color pendingColor = Color.fromARGB(255, 255, 151, 88);
  static const Color cancelColor = Colors.red;
  static const Color completeColor = Color.fromARGB(255, 98, 222, 53);

  static const Color appBarIconColor = Colors.white;
  static const Color lightTextColor = Color.fromARGB(255, 0, 0, 55);
  static const Color textAreaBackgroundColor = Color.fromARGB(255, 245, 247, 255);
  static const Color fadedIconColor = Color.fromARGB(255, 184, 193, 227);
  static const double appHorizontalPadding = 12;
  static const double paddingSmall = 6;
  static const double paddingLarge = 18;

  static String uuid() =>const Uuid().v4();



//   static String? ago(DateTime? dateTime) => dateTime == null ? null : TimeAgo.timeAgoSinceDate(dateTime);
// }

// class TimeAgo {
//   static String? timeAgoSinceDate(DateTime notificationDate, {bool numericDates = true}) {
//     final date2 = DateTime.now();
//     final difference = date2.difference(notificationDate);
//
//     if (difference.inDays > 8) {
//       return AppStyles.fd(notificationDate);
//     } else if ((difference.inDays / 7).floor() >= 1) {
//       return (numericDates) ? '1 week ago' : 'Last week';
//     } else if (difference.inDays >= 2) {
//       return '${difference.inDays} days ago';
//     } else if (difference.inDays >= 1) {
//       return (numericDates) ? '1 day ago' : 'Yesterday';
//     } else if (difference.inHours >= 2) {
//       return '${difference.inHours} hours ago';
//     } else if (difference.inHours >= 1) {
//       return (numericDates) ? '1 hour ago' : 'An hour ago';
//     } else if (difference.inMinutes >= 2) {
//       return '${difference.inMinutes} minutes ago';
//     } else if (difference.inMinutes >= 1) {
//       return (numericDates) ? '1 minute ago' : 'A minute ago';
//     } else if (difference.inSeconds >= 3) {
//       return '${difference.inSeconds} seconds ago';
//     } else {
//       return 'Just now';
//     }
//   }
 }
