import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late User currentUser;
  String userType = '';
  late List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    _getUserType(currentUser.uid);
  }

  Future<void> _getUserType(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      userType = userDoc['userType'];
      if (userType == 'parent') {
        _fetchTasks(userType, userId);
      } else if (userType == 'child') {
        _fetchChildTasks(userDoc['name'] ?? '');
      }
    });
  }

  Future<void> _fetchTasks(String userType, String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where(userType == 'parent' ? 'assignedBy' : 'assignedTo', isEqualTo: userId)
        .get();

    final allTasks = querySnapshot.docs.map((doc) {
      if (userType == 'parent') {
        return TaskModel.fromMap(doc.id, doc.data(), assignedBy: doc['assignedBy']);
      } else {
        return TaskModel.fromMap(doc.id, doc.data(), assignedBy: '');
      }
    }).toList();

    if (userType == 'parent') {
      final allUsersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final allUsers = allUsersSnapshot.docs.map((doc) => doc.id).toList();

      for (final user in allUsers) {
        if (user != userId) {
          final childTasksSnapshot = await FirebaseFirestore.instance
              .collection('tasks')
              .where('assignedTo', isEqualTo: user)
              .get();

          final childTasks = childTasksSnapshot.docs.map((doc) {
            return TaskModel.fromMap(doc.id, doc.data(), assignedBy: userId);
          }).toList();
          allTasks.addAll(childTasks);
        }
      }
    }

    setState(() {
      tasks = allTasks;
    });
  }

  Future<void> _fetchChildTasks(String name) async {
    final querySnapshot = await FirebaseFirestore.instance.collection('tasks').where('assignedTo', isEqualTo: name).get();

    final allTasks = querySnapshot.docs.map((doc) {
      return TaskModel.fromMap(doc.id, doc.data(), assignedBy: '');
    }).toList();

    // Fetch tasks assigned by parent to the child
    final parentTasksSnapshot = await FirebaseFirestore.instance.collection('tasks').where('assignedBy', isEqualTo: name).get();

    final parentTasks = parentTasksSnapshot.docs.map((doc) {
      return TaskModel.fromMap(doc.id, doc.data(), assignedBy: doc['assignedBy']);
    }).toList();

    allTasks.addAll(parentTasks); // Add parent-assigned tasks to the list

    setState(() {
      tasks = allTasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
      ),
      body: userType == 'child' ? _buildChildTasks() : _buildParentTasks(),
    );
  }

  Widget _buildChildTasks() {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _buildTaskItem(tasks[index]);
      },
    );
  }

  Widget _buildParentTasks() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            _showAddTaskDialog();
          },
          child: Text('Add Task'),
        ),
        SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _buildTaskItem(tasks[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(task.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assigned to: ${task.assignedTo}'),
            Text('Deadline: ${task.dueDate}'),
            Text('Points: ${task.redeemPoints}'),
          ],
        ),
        trailing: userType == 'parent'
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _showEditTaskDialog(task);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _removeTask(task);
              },
            ),
          ],
        )
            : null,
      ),
    );
  }

  void _showAddTaskDialog() {
    String description = '';
    String assignedTo = '';
    int redeemPoints = 0;
    String dueDate = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Task'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Description'),
                      onChanged: (value) {
                        description = value;
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Assigned To'),
                      onChanged: (value) {
                        assignedTo = value;
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Redeem Points'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        redeemPoints = int.tryParse(value) ?? 0;
                      },
                    ),
                    Row(
                      children: [
                        Text('Due Date: '),
                        TextButton(
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              setState(() {
                                dueDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                              });
                            }
                          },
                          child: Text(
                            dueDate.isEmpty ? 'Select Due Date' : dueDate,
                          ),
                        ),
                      ],
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
                    _addTask(description, assignedTo, redeemPoints, dueDate);
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTaskDialog(TaskModel task) {
    String description = task.description;
    String assignedTo = task.assignedTo;
    int redeemPoints = task.redeemPoints;
    String dueDate = task.dueDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Description'),
                      controller: TextEditingController(text: description),
                      onChanged: (value) {
                        description = value;
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Assigned To'),
                      controller: TextEditingController(text: assignedTo),
                      onChanged: (value) {
                        assignedTo = value;
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Redeem Points'),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: redeemPoints.toString()),
                      onChanged: (value) {
                        redeemPoints = int.tryParse(value) ?? 0;
                      },
                    ),
                    Row(
                      children: [
                        Text('Due Date: '),
                        TextButton(
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateFormat('yyyy-MM-dd').parse(dueDate),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              setState(() {
                                dueDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                              });
                            }
                          },
                          child: Text(
                            dueDate.isEmpty ? 'Select Due Date' : dueDate,
                          ),
                        ),
                      ],
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
                    _updateTask(task.id, description, assignedTo, redeemPoints, dueDate);
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateTask(String taskId, String description, String assignedTo, int redeemPoints, String dueDate) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'description': description,
      'assignedTo': assignedTo,
      'redeemPoints': redeemPoints,
      'dueDate': dueDate,
    });
    setState(() {
      final index = tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        tasks[index] = TaskModel(
          id: taskId,
          description: description,
          assignedTo: assignedTo,
          redeemPoints: redeemPoints,
          dueDate: dueDate,
          addedOn: tasks[index].addedOn, // Provide the existing addedOn value
          completed: tasks[index].completed,
          assignedBy: tasks[index].assignedBy, // Include assignedBy
        );
      }
    });
  }

  Future<void> _removeTask(TaskModel task) async {
    await FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
    setState(() {
      tasks.remove(task);
    });
  }

  Future<void> _addTask(String description, String assignedTo, int redeemPoints, String dueDate) async {
    String addedOn = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String assignedBy = currentUser.uid; // Assuming currentUser is the parent's user document

    await FirebaseFirestore.instance.collection('tasks').add({
      'description': description,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'redeemPoints': redeemPoints,
      'dueDate': dueDate,
      'addedOn': addedOn,
      'completed': false,
    });

    setState(() {
      tasks.add(TaskModel(
        id: 'generated_id', // You can set the ID accordingly based on the generated ID from Firestore
        description: description,
        assignedTo: assignedTo,
        redeemPoints: redeemPoints,
        dueDate: dueDate,
        addedOn: addedOn,
        assignedBy: assignedBy,
        completed: false,
      ));
    });
  }
}

class TaskModel {
  final String id;
  final String description;
  final String assignedTo;
  final String assignedBy; // Add assignedBy parameter
  final int redeemPoints;
  final String addedOn;
  final String dueDate;
  bool completed;

  TaskModel({
    required this.id,
    required this.description,
    required this.assignedTo,
    required this.assignedBy, // Add assignedBy parameter
    required this.redeemPoints,
    required this.addedOn,
    required this.dueDate,
    required this.completed,
  });

  factory TaskModel.fromMap(String id, Map<String, dynamic> map, {required String assignedBy}) {
    return TaskModel(
      id: id,
      description: map['description'],
      assignedTo: map['assignedTo'],
      assignedBy: assignedBy, // Assign value to assignedBy
      redeemPoints: map['redeemPoints'],
      addedOn: map['addedOn'],
      dueDate: map['dueDate'],
      completed: map['completed'],
    );
  }
}