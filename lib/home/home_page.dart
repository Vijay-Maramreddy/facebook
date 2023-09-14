import 'package:facebook/home/show_user_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class HomeScreen extends StatefulWidget {
   // Pass the user's email as a parameter
  final String email;

  const HomeScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            color: Colors.blue,
            onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShowUserDetailsPage(email: widget.email,),
                  ),
                );
            },
          ),
        ],
        flexibleSpace: Row(
          children: [
            IconButton(
              icon: Icon(Icons.facebook),
              color: Colors.blue, // Customize the color as needed
              onPressed: () {
                // Add your left-end icon onPressed functionality here.
              },
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white, // Customize the background color as needed
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body:
           const Center(
        child: Text('Welcome to Facebook'),
      ),
    );
  }
}
