import 'package:flutter/material.dart';

class RedeemPage extends StatefulWidget {
  @override
  _RedeemPageState createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  int totalPoints = 300; // Example: Total points earned by the user
  List<RewardModel> rewards = [
    RewardModel(description: 'Extra 30 minutes of screen time', redeemPoints: 50),
    RewardModel(description: 'New toy', redeemPoints: 100),
    RewardModel(description: 'Trip to the zoo', redeemPoints: 150),
    RewardModel(description: 'Pizza party with friends', redeemPoints: 200),
  ];
  List<RewardModel> redeemedRewards = []; // List to store redeemed rewards

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Redeem', style: TextStyle(fontSize: 22)),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('img/reward.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'Available Points: $totalPoints',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final reward = rewards[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 2,
                    child: ListTile(
                      title: Text(reward.description,
                          style: TextStyle(fontSize: 16)),
                      subtitle: Text('Redeem Points: ${reward.redeemPoints}',
                          style: TextStyle(fontSize: 14)),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _redeemReward(reward);
                        },
                        child: Text('Redeem'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _redeemReward(RewardModel reward) {
    if (totalPoints >= reward.redeemPoints) {
      setState(() {
        redeemedRewards.add(reward);
        totalPoints -= reward.redeemPoints;
      });
      // Show a confirmation message or perform other actions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reward.description} redeemed successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Show a message indicating insufficient points
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient points to redeem ${reward.description}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class RewardModel {
  final String description;
  final int redeemPoints;

  RewardModel({required this.description, required this.redeemPoints});
}