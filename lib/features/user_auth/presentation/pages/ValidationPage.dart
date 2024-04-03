import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TasksPage.dart'; // Import your TaskModel class here
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
            .where('status', isEqualTo: 'CompletedByChild')
            .get();

        setState(() {
          tasks = querySnapshot.docs
              .map((doc) => TaskModel.fromMap(
            doc.id,
            doc.data(),
            assignedBy: doc['assignedBy'], // Provide assignedBy parameter
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
        title: Text('Validation Page'),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.description),
            subtitle: Text('Assigned To: ${task.assignedTo}'),
            trailing: ElevatedButton(
              onPressed: () {
                // Mark the task as completed by parent and assign redeem points
                _completeTask(task);
              },
              child: Text('Complete'),
            ),
          );
        },
      ),
    );
  }

  Future<void> _completeTask(TaskModel task) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
        'status': 'CompletedByParent',
      });
      final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(task.id).get();
      final redeemPoints = taskDoc['redeemPoints'];
      print('Redeem Points: $redeemPoints');
      _fetchTasksForValidation();
    } catch (e) {
      print('Error completing task: $e');
    }
  }
}