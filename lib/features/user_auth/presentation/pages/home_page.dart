import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// Import pages
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
  late String userType = '';
  late User currentUser;
  List<Map<String, dynamic>> childProfiles = [];

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
    _loadChildProfiles();
  }

  Future<void> _getUserType(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      userType = userDoc.data()!['userType'] ?? '';
      _selectedIndex = 0;
    });
  }

  Future<void> _loadChildProfiles() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    if (userDoc.exists && userDoc.data()!['children'] != null) {
      List<String> childrenIds = List<String>.from(userDoc.data()!['children']);
      for (var childId in childrenIds) {
        var childData = await FirebaseFirestore.instance.collection('users').doc(childId).get();
        setState(() {
          childProfiles.add({
            'id': childId,
            'name': childData['name'],
            'email': childData['email']
          });
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
              childEmail = value.trim();
            },
            decoration: InputDecoration(hintText: 'Enter Child\'s Email'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                var querySnapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: childEmail)
                    .where('userType', isEqualTo: 'child')
                    .get();
                if (querySnapshot.docs.isNotEmpty) {
                  var childDoc = querySnapshot.docs.first;
                  List<String> updatedChildren = List.from(childProfiles.map((e) => e['id']))..add(childDoc.id);
                  await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({'children': updatedChildren});
                  setState(() {
                    childProfiles.add({
                      'id': childDoc.id,
                      'name': childDoc['name'],
                      'email': childDoc['email']
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Child profile added successfully.'),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('No child user found with that email.'),
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: !isDarkMode ? DecorationImage(
            image: AssetImage('assets/img/homepage.jpg'),
            fit: BoxFit.cover,
          ) : null,
        ),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'),
          if (userType == 'parent')
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(userType == 'parent' ? Icons.assignment_turned_in : Icons.redeem), label: userType == 'parent' ? 'Validation' : 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightBlue,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        selectedIconTheme: IconThemeData(size: 28),
        unselectedIconTheme: IconThemeData(size: 24),
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
      floatingActionButton: userType == 'parent' && _selectedIndex == 0
          ? FloatingActionButton(onPressed: () => _addChild(context), child: Icon(Icons.add))
          : null,
    );
  }
}

class HomePageContent extends StatelessWidget {
  final List<String> adviceList = [
    "Remember to break your tasks into smaller steps.",
    "Reward yourself after completing a challenging task.",
    "Set clear goals for each study session.",
  ];

  @override
  Widget build(BuildContext context) {
    int adviceIndex = Random().nextInt(adviceList.length);
    List<Map<String, dynamic>> childProfiles = (context.findAncestorStateOfType<_HomePageState>()?.childProfiles ?? []);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/img/homepage.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Spacer(),
          Text(
            adviceList[adviceIndex],
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Spacer(),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: childProfiles.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.white70,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${childProfiles[index]['name']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('${childProfiles[index]['email']}', style: TextStyle(fontSize: 14)),
                        Spacer(),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'Remove') {
                              _removeChild(context, childProfiles[index]['id']);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'Remove',
                              child: Text('Remove'),
                            ),
                          ],
                          icon: Icon(Icons.more_vert, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  void _removeChild(BuildContext context, String childId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      'children': FieldValue.arrayRemove([childId])
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Child removed successfully'),
      ));
      // Update local state
      context.findAncestorStateOfType<_HomePageState>()?.childProfiles.removeWhere((profile) => profile['id'] == childId);
      (context as Element).reassemble();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to remove child: $error'),
      ));
    });
  }
}
