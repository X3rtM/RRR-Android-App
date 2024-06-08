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
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    dateController = TextEditingController();
    _getUserType(currentUser.uid);
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  Future<void> _getUserType(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userType = userDoc['userType']?.toString() ?? '';
        setState(() {
          this.userType = userType;
          _fetchRewards();
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchRewards() async {
    try {
      QuerySnapshot querySnapshot;
      if (userType == 'child') {
        querySnapshot = await FirebaseFirestore.instance
            .collection('rewards')
            .where('assignedTo', isEqualTo: currentUser.uid)
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance.collection('rewards').get();
      }

      final List<RewardModel> allRewards = querySnapshot.docs.map((doc) {
        return RewardModel.fromMap(doc.id, doc.data());
      }).toList();

      setState(() {
        rewards = allRewards.where((reward) => reward.redemptionHistory.isEmpty).toList();
      });
    } catch (e) {
      print('Error fetching rewards: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Rewards'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: Colors.grey,
          ),
        ),
      ),
      body: Stack(
        children: [
          isDarkMode ? SizedBox.shrink() : Image.asset(
            'assets/img/reward.jpg',
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
            if (userType == 'parent' && reward.assignedTo != null)
              FutureBuilder<String?>(
                future: _getUserNameByUID(reward.assignedTo!),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Text(
                      'Assigned To: ${snapshot.data}',
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    );
                  }
                  return Text(
                    'Assigned To: ',
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  );
                },
              ),
            if (reward.dateUpTo != null)
              Text(
                'Expiry: ${DateFormat('dd MMM yyyy').format(reward.dateUpTo!)}',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            if (reward.redemptionHistory.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reward.redemptionHistory.map((redemption) {
                  return Text(
                    'Redeemed by: ${redemption['userName']} on ${DateFormat('dd MMM yyyy').format((redemption['date'] as Timestamp).toDate())}',
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  );
                }).toList(),
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
            : IconButton(
          icon: Icon(Icons.redeem),
          onPressed: () {
            _redeemReward(reward);
          },
        ),
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
    String assignedToName = '';
    String? errorText;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Reward'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
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
                      decoration: InputDecoration(labelText: 'Assigned To', errorText: errorText),
                      onChanged: (value) {
                        assignedToName = value;
                        _validateUserName(value).then((uid) {
                          setState(() {
                            assignedToUID = uid;
                            errorText = uid == null ? 'User doesn\'t exist' : null;
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
                          setState(() {
                            dateController.text = DateFormat('dd/MM/yyyy').format(value!);
                            selectedDate = value;
                          });
                        });
                      },
                    ),
                  ],
                ),
              );
            },
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
                if (errorText == null) {
                  _addReward(name, points, assignedToUID, selectedDate);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _validateUserName(String userName) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        List<dynamic> children = userDoc['children'];
        final userQuerySnapshot = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: userName).get();
        final userDocs = userQuerySnapshot.docs;
        if (userDocs.isNotEmpty) {
          final childUser = userDocs.first;
          if (children.contains(childUser.id)) {
            return childUser.id;
          }
        }
      }
    } catch (e) {
      print('Error validating user name: $e');
    }
    return null;
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
        'assignedTo': assignedTo,
        'dateUpTo': dateUpTo,
        'redemptionHistory': [], // Initialize as empty list
      });

      setState(() {
        rewards.add(RewardModel(
          id: '',
          name: name,
          points: points,
          assignedTo: assignedTo,
          dateUpTo: dateUpTo,
          redemptionHistory: [],
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

  void _redeemReward(RewardModel reward) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Redeem Reward'),
          content: Text('Are you sure you want to redeem this reward?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _processRedemption(reward);
                Navigator.of(context).pop();
              },
              child: Text('Redeem'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processRedemption(RewardModel reward) async {
    try {
      final redemption = {
        'userName': currentUser.displayName,
        'date': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('rewards').doc(reward.id).update({
        'redemptionHistory': FieldValue.arrayUnion([redemption]),
      });

      setState(() {
        rewards.remove(reward); // Remove the redeemed reward from the list
      });
    } catch (e) {
      print('Error redeeming reward: $e');
    }
  }
}

class RewardModel {
  final String id;
  final String name;
  final int points;
  final String? assignedTo;
  final DateTime? dateUpTo;
  final List<Map<String, dynamic>> redemptionHistory; // Add this field

  RewardModel({
    required this.id,
    required this.name,
    required this.points,
    this.assignedTo,
    this.dateUpTo,
    this.redemptionHistory = const [],
  });

  factory RewardModel.fromMap(String id, dynamic data) {
    final Map<String, dynamic> map = data as Map<String, dynamic>;
    return RewardModel(
      id: id,
      name: map['name'],
      points: map['points'],
      assignedTo: map['assignedTo'],
      dateUpTo: map['dateUpTo'] != null ? (map['dateUpTo'] as Timestamp).toDate() : null,
      redemptionHistory: List<Map<String, dynamic>>.from(map['redemptionHistory'] ?? []),
    );
  }
}
