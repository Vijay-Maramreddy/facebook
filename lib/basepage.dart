
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

