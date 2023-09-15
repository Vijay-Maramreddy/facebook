
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'AppAtyle.dart';

class BasePage extends StatelessWidget {
  const BasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}


// Function to show an alert dialog
void showAlert(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Alert'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // Close the dialog
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

// Example usage:
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Alert Example'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // Call the showAlert function to display the alert
              showAlert(context, 'This is a simple alert message.');
            },
            child: Text('Show Alert'),
          ),
        ),
      ),
    );
  }
}

final BoxDecoration customBoxDecoration = BoxDecoration(
  border: Border.all(
    color: Colors.black,
  ),
  borderRadius: BorderRadius.circular(10),
  color: Colors.white,
);



pickImage(ImageSource source) async{
  final ImagePicker _imagePicker =ImagePicker();
  XFile? _file=await _imagePicker.pickImage(source: source);
  if(_file !=null){
    return await _file.readAsBytes();
  }
  else{
    print("Image not found");
  }
}

Widget imagePicker(bool imageList, Function() onClick, String title1, String title2) {
  return GestureDetector(
      onTap: onClick,
      child: Container(
          height: imageList ? 50 : 100,
          decoration: BoxDecoration(color: const Color.fromARGB(255, 203, 231, 221), borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(vertical: AppStyles.appHorizontalPadding / 2),
          padding: const EdgeInsets.all(AppStyles.appHorizontalPadding),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!imageList) ...[
                Icon(
                  Icons.camera_alt,
                  size: imageList ? 4 : 12,
                  color: Colors.orange,
                )
              ],
              Text(
                imageList ? title1 : title2,
                style: const TextStyle(color: Colors.black38),
              )
            ],
          )));
}


