import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
}

enum SortBy {
  Name,
  DueDate,
  AssignedOn,
  Points,
}

DateTime _parseDate(String dateString) {
  List<String> dateParts = dateString.split('-');
  int year = int.parse(dateParts[2]);
  int month = int.parse(dateParts[1]);
  int day = int.parse(dateParts[0]);
  return DateTime(year, month, day);
}

class _TasksPageState extends State<TasksPage> {
  late User currentUser;
  String userType = '';
  late List<TaskModel> tasks = [];
  SortBy sortBy = SortBy.Name;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    _isMounted=true;
    _getUserType(currentUser.uid);
  }

  @override
  void dispose() {
    _isMounted = false; // Set flag to false when disposed
    super.dispose();
  }

  Future<void> _getUserType(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      userType = userDoc['userType'];
      if (userType == 'parent') {
        _fetchTasks(userType, userId);
      } else if (userType == 'child') {
        _fetchChildTasks(userId);
      }
    });
  }

  Future<void> _fetchTasks(String userType, String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where(userType == 'parent' ? 'assignedBy' : 'assignedTo', isEqualTo: userId)
          .get();

      final List<TaskModel> allTasks = querySnapshot.docs.map((doc) {
        return TaskModel.fromMap(
          doc.id,
          doc.data(),
          assignedBy: doc['assignedBy'],
        );
      }).toList();

      // Sorting tasks by user names
      if (_isMounted) {
        allTasks.sort((task1, task2) {
          switch (sortBy) {
            case SortBy.Name:
              return task1.assignedTo.toLowerCase().compareTo(
                  task2.assignedTo.toLowerCase());
            case SortBy.DueDate:
              return task1.dueDate.compareTo(task2.dueDate);
            case SortBy.AssignedOn:
              return task1.addedOn.compareTo(task2.addedOn);
            case SortBy.Points:
              return task1.redeemPoints.compareTo(task2.redeemPoints);
          }
        });

        if (_isMounted) {
          setState(() {
            tasks = allTasks;
          });
        }
      }
    } catch (e) {
      if(_isMounted) {
        print('Error fetching tasks: $e');
      }
    }
  }

  Future<void> _fetchChildTasks(String uid) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: uid)
          .get();

      final List<TaskModel> allTasks = querySnapshot.docs.map((doc) {
        return TaskModel.fromMap(doc.id, doc.data(), assignedBy: '');
      }).toList();

      if (_isMounted) {
        if (_searchText.isNotEmpty) {
          // Filter tasks based on search text
          allTasks.retainWhere((task) =>
              task.description.toLowerCase().contains(_searchText.toLowerCase()));
        }

        // Sort tasks based on selected criteria
        allTasks.sort((task1, task2) {
          switch (sortBy) {
            case SortBy.Name:
              return task1.description.toLowerCase().compareTo(task2.description.toLowerCase());
            case SortBy.DueDate:
              return _parseDate(task1.dueDate).compareTo(_parseDate(task2.dueDate));
            case SortBy.AssignedOn:
              return _parseDate(task1.addedOn).compareTo(_parseDate(task2.addedOn));
            case SortBy.Points:
              return task1.redeemPoints.compareTo(task2.redeemPoints);
            default:
              return 0;
          }
        });

        setState(() {
          tasks = allTasks;
        });
      }
    } catch (e) {
      if (_isMounted) {
        print('Error fetching child tasks: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('img/task.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: userType == 'child' ? _buildChildTasks() : _buildParentTasks(),
      ),
    );
  }

  Widget _buildParentTasks() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            _showAddTaskDialog();
          },
          child: Text('Add Task'),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildSearchBar((filteredTasks) {
                  setState(() {
                    tasks = filteredTasks;
                  });
                }, isParent: true),
              ),
            ),
            PopupMenuButton<SortBy>(
              onSelected: (sortBy) {
                setState(() {
                  this.sortBy = sortBy;
                });
                _fetchTasks('parent', userId); // Fetch tasks with updated sorting
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SortBy>>[
                PopupMenuItem<SortBy>(
                  value: SortBy.DueDate,
                  child: Text('Sort by Due Date'),
                ),
                PopupMenuItem<SortBy>(
                  value: SortBy.AssignedOn,
                  child: Text('Sort by Assigned On'),
                ),
                PopupMenuItem<SortBy>(
                  value: SortBy.Name,
                  child: Text('Sort by Name'),
                ),
              ],
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              }
              List<TaskModel> tasksList = tasks;
              if (snapshot.hasData) {
                tasksList = tasksList.where((task) {
                  return task.description.toLowerCase().contains(_searchText.toLowerCase()) ||
                      task.assignedTo.toLowerCase().contains(_searchText.toLowerCase());
                }).toList();

                tasksList.sort((a, b) {
                  switch (sortBy) {
                    case SortBy.Name:
                      return a.assignedTo.toLowerCase().compareTo(b.assignedTo.toLowerCase());
                    case SortBy.DueDate:
                      return _parseDate(b.dueDate).compareTo(_parseDate(a.dueDate)); // Sort in descending order
                    case SortBy.AssignedOn:
                      return _parseDate(b.addedOn).compareTo(_parseDate(a.addedOn)); // Sort in descending order
                    case SortBy.Points:
                      return a.redeemPoints.compareTo(b.redeemPoints);
                    default:
                      return 0; // Default case
                  }
                });
              }

              return ListView.builder(
                itemCount: tasksList.length,
                itemBuilder: (context, index) {
                  return _buildTaskItem(tasksList[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChildTasks() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildSearchBar((filteredTasks) {
                  setState(() {
                    tasks = filteredTasks;
                  });
                }, isParent: false),
              ),
            ),
            PopupMenuButton<SortBy>(
              onSelected: (sortBy) {
                setState(() {
                  this.sortBy = sortBy;
                });
                _fetchTasks('child', userId); // Fetch tasks with updated sorting
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SortBy>>[
                PopupMenuItem<SortBy>(
                  value: SortBy.DueDate,
                  child: Text('Sort by Due Date'),
                ),
                PopupMenuItem<SortBy>(
                  value: SortBy.AssignedOn,
                  child: Text('Sort by Assigned On'),
                ),
                PopupMenuItem<SortBy>(
                  value: SortBy.Points,
                  child: Text('Sort by Points'),
                ),
              ],
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              }
              List<TaskModel> tasksList = tasks;
              if (snapshot.hasData) {
                tasksList = tasksList.where((task) {
                  return task.description.toLowerCase().contains(_searchText.toLowerCase());
                }).toList();
                switch (sortBy) {
                  case SortBy.DueDate:
                    tasksList.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                    break;
                  case SortBy.AssignedOn:
                    tasksList.sort((a, b) => a.addedOn.compareTo(b.addedOn));
                    break;
                  case SortBy.Points:
                    tasksList.sort((a, b) => a.redeemPoints.compareTo(b.redeemPoints));
                    break;
                  default:
                    break;
                }
              }
              return ListView.builder(
                itemCount: tasksList.length,
                itemBuilder: (context, index) {
                  return _buildTaskItem(tasksList[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<TaskModel> filterAndSortTasks(List<TaskModel> allTasks) {
    String searchQuery = _searchController.text.toLowerCase();
    List<TaskModel> filteredTasks = allTasks.where((task) =>
    task.description.toLowerCase().contains(searchQuery) ||
        task.assignedTo.toLowerCase().contains(searchQuery)).toList();

    switch (sortBy) {
      case SortBy.DueDate:
        filteredTasks.sort((task1, task2) => task1.dueDate.compareTo(task2.dueDate));
        break;
      case SortBy.AssignedOn:
        filteredTasks.sort((task1, task2) => task1.addedOn.compareTo(task2.addedOn));
        break;
      case SortBy.Name:
        filteredTasks.sort((task1, task2) => task1.assignedTo.toLowerCase().compareTo(task2.assignedTo.toLowerCase()));
        break;
      default:
      // Default sorting behavior, no need to sort here
        break;
    }
    return filteredTasks;
  }

  TextField buildSearchBar(Function(List<TaskModel>) filterTasks, {required bool isParent}) {
    return TextField(
      controller: _searchController, // Use the search controller
      onChanged: (value) {
        setState(() {
          _searchText = value; // Update the search text
        });
        List<TaskModel> filtered = tasks.where((task) {
          if (isParent) {
            return task.description.toLowerCase().contains(_searchText.toLowerCase()) ||
                task.assignedTo.toLowerCase().contains(_searchText.toLowerCase());
          } else {
            return task.description.toLowerCase().contains(_searchText.toLowerCase());
          }
        }).toList();
        filterTasks(filtered);
      },
      decoration: InputDecoration(
        hintText: isParent ? 'Search by description or name' : 'Search by description',
        border: OutlineInputBorder(),
      ),
    );
  }

  String _formatDate(String dateString) {
    // Split the dateString using "-" as the separator
    List<String> dateParts = dateString.split('-');

    // Ensure that there are three parts (day, month, year)
    if (dateParts.length == 3) {
      int day = int.tryParse(dateParts[0]) ?? 0;
      int month = int.tryParse(dateParts[1]) ?? 0;
      int year = int.tryParse(dateParts[2]) ?? 0;

      // Create a DateTime object from the parsed parts
      DateTime dateTime = DateTime(year, month, day);

      // Format the DateTime object as required
      String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);

      return formattedDate;
    } else {
      return ''; // Return empty string if the date format is invalid
    }
  }

  Widget _buildTaskItem(TaskModel task) {
    Color statusColor = task.completed ? Colors.green : Colors.red;
    String statusText = task.completed ? 'Completed' : 'Not Completed';

    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(task.description),
        subtitle: Table(
          columnWidths: {
            0: FlexColumnWidth(1), // Assign equal flex to each column
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned On: ${_formatDate(task.addedOn)}'),
                      Text('Points: ${task.redeemPoints}'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deadline: ${_formatDate(task.dueDate)}'),
                      Text('Status: $statusText', style: TextStyle(color: statusColor)),
                    ],
                  ),
                ),
                if (userType == 'parent')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(task.assignedTo).get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text('Assigned To: Loading...'); // Show loading indicator
                            }
                            if (snapshot.hasError) {
                              return Text('Error: Unable to fetch user data'); // Show error message
                            }
                            if (snapshot.hasData && snapshot.data!.exists) {
                              Map<String, dynamic>? userData = snapshot.data!.data() as Map<String, dynamic>?;

                              // Display the name of the child user
                              return Text('Assigned To: ${userData?['name'] ?? 'Unknown'}');
                            } else {
                              return Text('Assigned To: Unknown'); // Show if user data doesn't exist
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                if (userType == 'child')
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _updateTaskStatus(task);
                          },
                        ),
                      ),
                    ],
                  ),
                if (userType == 'parent')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
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
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateTaskStatus(TaskModel task) {
    String taskId = task.id;
    bool newStatus = !task.completed;

    FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'completed': newStatus,
    }).then((_) {
      setState(() {
        task.completed = newStatus;
      });
      print('Task status updated successfully');
    }).catchError((error) {
      print('Error updating task status: $error');
    });
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
                                dueDate = DateFormat('dd-MM-yyyy').format(selectedDate);
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
    String assignedTo = task.assignedTo; // Assuming assignedTo initially contains the UID
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
                    StreamBuilder<String>(
                      stream: _resolveUserNameStream(assignedTo), // Resolve the user's name
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          String? userName = snapshot.data; // Use a nullable variable
                          assignedTo = userName ?? ''; // If userName is null, assign an empty string
                          return TextField(
                            decoration: InputDecoration(labelText: 'Assigned To'),
                            controller: TextEditingController(text: userName), // Set the name directly
                            onChanged: (value) {
                              assignedTo = value; // Update assignedTo with the name
                            },
                          );
                        } else {
                          return CircularProgressIndicator(); // Display a loading indicator while resolving the name
                        }
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
                              initialDate: DateFormat('dd-MM-yyyy').parse(dueDate),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              setState(() {
                                dueDate = DateFormat('dd-MM-yyyy').format(selectedDate);
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
    String assignedToUid = await _resolveUserUID(assignedTo); // Resolve the UID from the name

    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'description': description,
      'assignedTo': assignedToUid, // Store the resolved UID
      'redeemPoints': redeemPoints,
      'dueDate': dueDate,
    });

    setState(() {
      final index = tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        tasks[index] = TaskModel(
          id: taskId,
          description: description,
          assignedTo: assignedTo, // Update assignedTo with the name
          redeemPoints: redeemPoints,
          dueDate: dueDate,
          addedOn: tasks[index].addedOn,
          completed: tasks[index].completed,
          assignedBy: tasks[index].assignedBy,
        );
      }
    });
  }

  Stream<String> _resolveUserNameStream(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot['name'];
      } else {
        return ''; // Return empty string if user document doesn't exist
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
    String addedOn = DateFormat('dd-MM-yyyy').format(DateTime.now());
    String assignedBy = currentUser.uid; // Assuming currentUser is the parent's user document

    // Resolve the UID based on the assignedTo string
    String assignedToUid = await _resolveUserUID(assignedTo);

    DocumentReference newTaskRef = await FirebaseFirestore.instance.collection('tasks').add({
      'description': description,
      'assignedTo': assignedToUid, // Save the UID of the assigned user
      'assignedBy': assignedBy,
      'redeemPoints': redeemPoints,
      'dueDate': dueDate,
      'addedOn': addedOn,
      'completed': false,
    });

    String taskId = newTaskRef.id; // Retrieve the ID of the newly added document

    setState(() {
      tasks.add(TaskModel(
        id: taskId, // Use the retrieved ID
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

// Function to resolve the UID based on the assignedTo string
  Future<String> _resolveUserUID(String assignedTo) async {
    String assignedToUid = '';
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: assignedTo)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      assignedToUid = userSnapshot.docs.first.id;
    }

    return assignedToUid;
  }
}

class TaskModel {
  final String id;
  final String description;
  final String assignedTo; // Include assignedTo for parent user type
  final String assignedBy;
  final int redeemPoints;
  final String addedOn;
  final String dueDate;
  bool completed;

  TaskModel({
    required this.id,
    required this.description,
    required this.assignedTo,
    required this.assignedBy,
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
      assignedBy: assignedBy,
      redeemPoints: map['redeemPoints'],
      addedOn: map['addedOn'],
      dueDate: map['dueDate'],
      completed: map['completed'],
    );
  }
}