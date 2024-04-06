import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TasksPage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ValidationPage extends StatefulWidget {
  @override
  _ValidationPageState createState() => _ValidationPageState();
}

class _ValidationPageState extends State<ValidationPage> {
  late List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasksForValidation();
  }

  Future<void> _fetchTasksForValidation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedBy', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'MarkedByChild') // Filter by completed tasks
            .get();

        setState(() {
          tasks = querySnapshot.docs
              .map((doc) => TaskModel.fromMap(
            doc.id,
            doc.data(),
            assignedBy: doc['assignedBy'],
          ))
              .toList();
        });
      } catch (e) {
        print('Error fetching tasks for validation: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Validation Page'),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildTaskItem(task);
        },
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(task.description),
        subtitle: FutureBuilder(
          future: _fetchAssignedUserName(task.assignedTo),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Assigned To: Loading...');
            } else if (snapshot.hasError) {
              return Text('Assigned To: Error loading user name');
            } else {
              final userName = snapshot.data as String?;
              return Text('Assigned To: ${userName ?? 'Unknown'}');
            }
          },
        ),
        trailing: ElevatedButton(
          onPressed: () {
            _completeTask(task);
          },
          child: Text('Complete'),
        ),
      ),
    );
  }

  Future<String?> _fetchAssignedUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null) {
        return userData['name']; // Return the user's name
      }
    } catch (e) {
      print('Error fetching assigned user name: $e');
    }
    return null;
  }

  _completeTask(TaskModel task) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
        'status': 'MarkedByParent',
      });
      final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(task.id).get();
      final redeemPoints = taskDoc['redeemPoints'];
      final userId = task.assignedTo; // Get userId from task
      print('Redeem Points: $redeemPoints');
      _updateUserPoints(redeemPoints, userId); // Pass userId
      _fetchTasksForValidation();
    } catch (e) {
      print('Error completing task: $e');
    }
  }

  Future<void> _updateUserPoints(int redeemPoints, String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null && userData['userType'] == 'child') {
        final currentPoints = userData['cur_points'] ?? 0;
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'cur_points': currentPoints + redeemPoints, // Increment user points
        });
      }
    } catch (e) {
      print('Error updating user points: $e');
    }
  }
}