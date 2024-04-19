import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'TasksPage.dart';
import 'ProfilePage.dart';
import 'SettingsPage.dart';
import 'ValidationPage.dart';
import 'RewardsPage.dart';
import 'RedeemPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Result Reward Redemption System',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late String userType = ''; // Provide a default value
  late User currentUser;

  final List<Widget> _pagesParent = [
    HomePageContent(),
    TasksPage(),
    RewardsPage(),
    ValidationPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  final List<Widget> _pagesChild = [
    HomePageContent(),
    TasksPage(),
    RedeemPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    _getUserType(currentUser.uid);
  }

  Future<void> _getUserType(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      userType = userDoc['userType'] ?? ''; // Ensure userType is initialized
      _selectedIndex = 0;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _sendVerificationEmail(String parentName, String childEmail) async {
    final smtpServer = gmail('your@gmail.com', 'yourpassword');

    final message = Message()
      ..from = Address('your@gmail.com', 'Your Name')
      ..recipients.add(childEmail)
      ..subject = 'Child Verification Request'
      ..text = '$parentName has sent a child verification request. Please click on the following link to verify: http://example.com/verify'
      ..html = '<p>$parentName has sent a child verification request.</p><p>Please click on the following link to verify: <a href="http://example.com/verify">Verify Parent</a></p>';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error occurred while sending email: $e');
    }
  }

  Future<void> _addChild(BuildContext context) async {
    String childEmail = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Your Child'),
          content: TextField(
            onChanged: (value) {
              childEmail = value;
            },
            decoration: InputDecoration(hintText: 'Enter Child\'s Email'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Send verification email to childEmail
                try {
                  String parentName = FirebaseAuth.instance.currentUser!.displayName ?? 'Parent';
                  await _sendVerificationEmail(parentName, childEmail);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Verification email sent to $childEmail'),
                  ));
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to send verification email: $error'),
                  ));
                }
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = userType == 'parent' ? _pagesParent : _pagesChild;

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 8), // Adjust vertical padding as needed
              child: Icon(Icons.home),
            ),
            label: '', // Set label to empty string
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 8), // Adjust vertical padding as needed
              child: Icon(Icons.assignment),
            ),
            label: '', // Set label to empty string
          ),
          if (userType == 'parent')
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.symmetric(vertical: 8), // Adjust vertical padding as needed
                child: Icon(Icons.card_giftcard),
              ),
              label: '', // Set label to empty string
            ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 8), // Adjust vertical padding as needed
              child: Icon(userType == 'parent' ? Icons.assignment_turned_in : Icons.redeem),
            ),
            label: '', // Set label to empty string
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 8), // Adjust vertical padding as needed
              child: Icon(Icons.person),
            ),
            label: '', // Set label to empty string
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 0), // Adjust vertical padding as needed
              child: Icon(Icons.settings),
            ),
            label: '', // Set label to empty string
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightBlue,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        selectedIconTheme: IconThemeData(size: 28),
        unselectedIconTheme: IconThemeData(size: 24),
      ),
      floatingActionButton: userType == 'parent' && _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: () => _addChild(context),
        child: Icon(Icons.add),
      )
          : null,
    );
  }
}

class HomePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/img/homepage.jpg'), // Adjust path as per your image location
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}