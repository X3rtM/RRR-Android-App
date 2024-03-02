import 'package:flutter/material.dart';

class RewardsPage extends StatelessWidget {
  final List<RewardModel> rewards = [
    RewardModel(description: 'Extra 30 minutes of screen time', redeemPoints: 50),
    RewardModel(description: 'New toy', redeemPoints: 100),
    RewardModel(description: 'Trip to the zoo', redeemPoints: 150),
    RewardModel(description: 'Pizza party with friends', redeemPoints: 200),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rewards', style: TextStyle(fontSize: 22)),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('img/reward.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView.builder(
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 2,
              child: ListTile(
                title: Text(rewards[index].description,
                    style: TextStyle(fontSize: 16)),
                subtitle: Text('Redeem Points: ${rewards[index].redeemPoints}',
                    style: TextStyle(fontSize: 14)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RewardModel {
  final String description;
  final int redeemPoints;

  RewardModel({required this.description, required this.redeemPoints});
}