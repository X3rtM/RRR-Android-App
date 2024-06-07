
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TasksPage.dart';
import 'ProfilePage.dart';
import 'SettingsPage.dart';
import 'ValidationPage.dart';
import 'RewardsPage.dart';
import 'RedeemPage.dart';
import 'NotificationPage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late String userType = '';
  late User currentUser;
  List<Map<String, dynamic>> childProfiles = [];
  int _notificationCount=0;

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
    NotificationPage(),
  ];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    _getUserType(currentUser.uid);
    _loadChildProfiles();
    _listenForNotifications();
  }

  Future<void> _getUserType(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      userType = userDoc.data()!['userType'] ?? '';
      _selectedIndex = 0;
    });
  }

  Future<void> _listenForNotifications() async{
    FirebaseFirestore.instance.collection('tasks').where('assignedTo',isEqualTo: currentUser.uid).snapshots().listen((snapshot){
      int newNotificationCount=0;
      snapshot.docs.forEach((doc){
        if (doc['status']=='Incomplete' || doc['status']=='MarkedByParent'){
          newNotificationCount++;
        }
      });
      setState(() {
        _notificationCount=newNotificationCount;
      });
    });
  }

  Future<void> _loadChildProfiles() async {
    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    List<Map<String, dynamic>> profiles = [];
    if (userDoc.exists && userDoc.data()!['children'] != null) {
      List<String> childrenIds = List<String>.from(userDoc.data()!['children']);
      for (var childId in childrenIds) {
        var childData =
        await FirebaseFirestore.instance.collection('users').doc(childId).get();
        profiles.add({
          'id': childId,
          'name': childData['name'],
          'email': childData['email']
        });
      }
    }
    setState(() {
      childProfiles = profiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages;
    if (userType == 'parent') {
      pages = _pagesParent;
    } else {
      pages = _pagesChild;
    }    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
        automaticallyImplyLeading: false,
        title: Text('Home Page'),
      actions: <Widget>[
        if (userType=='child')
          Stack(
            children: [
              IconButton(icon: Icon(Icons.notifications, color:Colors.grey),
                  onPressed: (){
                    Navigator.push(context,MaterialPageRoute(builder: (context)=>NotificationPage()));
                  },
              ),
              Positioned(
                  right:0,
                  top:0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color:Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style:TextStyle(
                        color:Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
    height: 1.0,
    color:Colors.grey,
    ),
          ),
      )
        :null,
      body: Container(
        decoration: BoxDecoration(
          image: isDarkMode ? null: DecorationImage(
            image: AssetImage('assets/img/homepage.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Container(
        height: 1.0,
        color: Colors.grey,
      ),
      BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'Tasks'),
          if (userType == 'parent')
            BottomNavigationBarItem(
                icon: Icon(Icons.card_giftcard), label: 'Rewards'),
          BottomNavigationBarItem(
              icon: Icon(userType == 'parent'
                  ? Icons.assignment_turned_in
                  : Icons.redeem),
              label: userType == 'parent' ? 'Validation' : 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
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
      ],
      ),
      floatingActionButton: userType == 'parent' && _selectedIndex == 0
          ? FloatingActionButton(
          onPressed: () => _addChild(context), child: Icon(Icons.add))
          : null,
    );
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
                  List<String> updatedChildren =
                  List.from(childProfiles.map((e) => e['id']))
                    ..add(childDoc.id);
                  User? currentUser = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .update({
                    'children': updatedChildren,
                  });
                  // Update child profiles list here
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class HomePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> childProfiles =(context.findAncestorStateOfType<_HomePageState>()?.childProfiles ?? []);
    bool isDarkMode = Theme.of(context).brightness==Brightness.dark;
    _HomePageState? homePageState = context.findAncestorStateOfType<_HomePageState>();
    String userType= context.findAncestorStateOfType<_HomePageState>()?.userType ?? '';

    return Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: userType == 'parent'
            ? _buildParentContent(homePageState?.childProfiles ?? [])
            : _buildChildContent(context),
      ),
    );
  }

  Widget _buildParentContent(List<Map<String, dynamic>> childProfiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (childProfiles.isNotEmpty) ...[
          Expanded(
            child: _buildChildCards(childProfiles),
          ),
        ],
        _buildTable(),
      ],
    );
  }

  Widget _buildChildContent(BuildContext context) {
    return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome Child!',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TasksPage()));
              },
              child: Text('Complete a Task'),
            ),
            SizedBox(height: 20),
            Text(
              'Task Advice:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 10),
            Table(
              border: TableBorder.all(color: Colors.black),
              columnWidths: {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Common Advice',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Important Advice',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Stay organized'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Focus on one task at a time'),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Set specific goals'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Take breaks when needed'),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Prioritize tasks'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Ask for help if needed'),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Break tasks into smaller steps'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Stay positive and motivated'),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Avoid multitasking'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Celebrate your achievements'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
    );
  }

  Widget _buildTable() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Advice:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 10),
            Table(
              border: TableBorder.all(color: Colors.black),
              columnWidths: {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Age Group',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Task Advice',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('0-3 years'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Simple tasks like stacking blocks or identifying colors.',
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('4-6 years'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Tasks involving counting, simple puzzles, or drawing shapes.',
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('7-9 years'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'More complex puzzles, reading comprehension, basic math operations.',
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('10-12 years'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Advanced math, writing essays, critical thinking tasks.',
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('13-15 years'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'High school level tasks, research projects, exam preparation.',
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('16+ years'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'College-level assignments, career planning, internships.',
                        ),
                      ),
                    ),
                  ],
                ),
                // Add more rows for additional age groups and their advice as needed
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCards(List<Map<String, dynamic>> childProfiles) {
    return GridView.builder(
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
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${childProfiles[index]['name']}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text('${childProfiles[index]['email']}', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
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
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeChild(BuildContext context, String childId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      'children': FieldValue.arrayRemove([childId])
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Child removed successfully'),
        ),
      );
      // Update local state if it's still mounted
      if (context.findAncestorStateOfType<_HomePageState>()?.mounted ?? false) {
        context.findAncestorStateOfType<_HomePageState>()?.setState(() {
          context.findAncestorStateOfType<_HomePageState>()?.childProfiles.removeWhere((profile) => profile['id'] == childId);
        });
      }
      // Delay before reloading the homepage
      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove child: $error'),
        ),
      );
    });
  }
}
