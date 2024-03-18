import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Notifications'),
            trailing: Switch(
              value: true, // Change to a bool variable to control the state of the switch
              onChanged: (bool value) {
                // Implement logic to handle notifications
              },
            ),
          ),
          ListTile(
            title: Text('Dark Mode'),
            trailing: Switch(
              value: false, // Change to a bool variable to control the state of the switch
              onChanged: (bool value) {
                // Implement logic to toggle dark mode
              },
            ),
          ),
          ListTile(
            title: Text('Language'),
            trailing: DropdownButton<String>(
              value: 'English',
              onChanged: (String? newValue) {
                // Implement logic to change the app language
              },
              items: <String>['English', 'Spanish', 'French'] // Add supported languages here
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: Text('Logout'),
            onTap: () {
              // Implement logout logic
            },
          ),
        ],
      ),
    );
  }
}
