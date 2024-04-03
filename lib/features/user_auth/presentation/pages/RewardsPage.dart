import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RewardsPage extends StatefulWidget {
  @override
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  late User currentUser;
  String userType = '';
  late List<RewardModel> rewards = [];

  // Define variables to hold the values for adding rewards
  late String rewardAssignedTo;
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    _getUserType(currentUser.uid);
    dateController = TextEditingController();
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  Future<void> _getUserType(String userId) async {
    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userType = userDoc['userType']?.toString() ?? ''; // Safely handle null value
    setState(() {
      this.userType = userType;
      _fetchRewards();
    });
  }
  Future<void> _fetchRewards() async {
    try {
      QuerySnapshot querySnapshot;
      if (userType == 'child') {
        // Fetch rewards assigned to the current user
        querySnapshot = await FirebaseFirestore.instance
            .collection('rewards')
            .where('assignedTo', isEqualTo: currentUser.uid)
            .get();
      } else {
        // Fetch all rewards if the user is a parent
        querySnapshot =
        await FirebaseFirestore.instance.collection('rewards').get();
      }

      final List<RewardModel> allRewards = querySnapshot.docs.map((doc) {
        return RewardModel.fromMap(doc.id, doc.data());
      }).toList();

      setState(() {
        rewards = allRewards;
      });
    } catch (e) {
      print('Error fetching rewards: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rewards'),
      ),
      body: Stack(
        children: [
          Image.asset(
            'assets/img/reward.jpg', // Replace 'assets/background.jpg' with your image path
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: userType == 'child' ? _buildChildRewards() : _buildParentRewards(),
          ),
        ],
      ),
      floatingActionButton: userType == 'parent' ? _buildAddRewardButton() : null,
    );
  }

  Widget _buildParentRewards() {
    return ListView.builder(
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        return _buildRewardItem(rewards[index]);
      },
    );
  }

  Widget _buildChildRewards() {
    return ListView.builder(
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        return _buildRewardItem(rewards[index]);
      },
    );
  }

  Widget _buildRewardItem(RewardModel reward) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        title: Text(
          reward.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points: ${reward.points}',
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
            if (userType == 'parent' && reward.assignedTo != null) // Only display when userType is 'parent' and assignedTo is not null
              FutureBuilder<String?>(
                future: _getUserNameByUID(reward.assignedTo!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return Text(
                      'Assigned To: ${snapshot.data}',
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    );
                  }
                  return Text(
                    'Assigned To: Unknown',
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  );
                },
              ),
            if (reward.dateUpTo != null) // Check if dateUpTo is not null
              Text(
                'Date Up To: ${DateFormat('dd MMM yyyy').format(reward.dateUpTo!)}',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
          ],
        ),
        trailing: userType == 'parent'
            ? IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            _removeReward(reward);
          },
        )
            : null,
      ),
    );
  }

  Future<String?> _getUserNameByUID(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc['name'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return null;
    }
  }

  Widget _buildAddRewardButton() {
    return FloatingActionButton(
      onPressed: () {
        _showAddRewardDialog();
      },
      child: Icon(Icons.add),
    );
  }

  void _showAddRewardDialog() {
    String name = '';
    int points = 0;
    DateTime? selectedDate;
    String? assignedToUID;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Reward'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Name'),
                  onChanged: (value) {
                    name = value;
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Points'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    points = int.tryParse(value) ?? 0;
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Assigned To'),
                  onChanged: (value) {
                    // Fetch UID of the child user based on their name
                    _getUserUIDByName(value).then((uid) {
                      setState(() {
                        assignedToUID = uid;
                      });
                    });
                  },
                ),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Expiry (dd/MM/yyyy)'),
                  onTap: () {
                    _selectDate(context).then((value) {
                      dateController.text = DateFormat('dd/MM/yyyy').format(value!);
                      selectedDate = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addReward(name, points, assignedToUID, selectedDate);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _getUserUIDByName(String userName) async {
    final userQuerySnapshot = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: userName).get();
    final userDocs = userQuerySnapshot.docs;
    if (userDocs.isNotEmpty) {
      return userDocs.first.id; // Return the UID of the first user with the given name
    } else {
      return null; // Return null if no user found with the given name
    }
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    return pickedDate;
  }

  Future<void> _addReward(String name, int points, String? assignedTo, DateTime? dateUpTo) async {
    try {
      await FirebaseFirestore.instance.collection('rewards').add({
        'name': name,
        'points': points,
        'assignedTo': assignedTo, // Store assignedTo field in Firestore
        'dateUpTo': dateUpTo, // Store dateUpTo field in Firestore
      });

      setState(() {
        rewards.add(RewardModel(
          id: '',
          name: name,
          points: points,
          assignedTo: assignedTo, // Assign assignedTo field
          dateUpTo: dateUpTo, // Assign dateUpTo field
        ));
      });
    } catch (e) {
      print('Error adding reward: $e');
    }
  }

  Future<void> _removeReward(RewardModel reward) async {
    try {
      await FirebaseFirestore.instance.collection('rewards').doc(reward.id).delete();
      setState(() {
        rewards.remove(reward);
      });
    } catch (e) {
      print('Error removing reward: $e');
    }
  }
}

class RewardModel {
  final String id;
  final String name;
  final int points;
  final String? assignedTo; // Assigned to field
  final DateTime? dateUpTo; // Date up to field

  RewardModel({
    required this.id,
    required this.name,
    required this.points,
    this.assignedTo, // Initialize assignedTo field
    this.dateUpTo, // Initialize dateUpTo field
  });

  factory RewardModel.fromMap(String id, dynamic data) {
    final Map<String, dynamic> map = data as Map<String, dynamic>;
    return RewardModel(
      id: id,
      name: map['name'],
      points: map['points'],
      assignedTo: map['assignedTo'], // Assign assignedTo value
      dateUpTo: map['dateUpTo'] != null ? (map['dateUpTo'] as Timestamp).toDate() : null, // Assign dateUpTo value
    );
  }

}
