import 'package:flutter/material.dart';

import 'models/companion_bot_mood.dart';
import 'widgets/home_header.dart';
import 'widgets/robot_hero_card.dart';

class RobotHomePage extends StatelessWidget {
  const RobotHomePage({
    required this.mood,
    required this.onFullScreenTap,
    super.key,
  });

  final CompanionBotMood mood;
  final VoidCallback onFullScreenTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 144),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),
              const SizedBox(height: 16),
              RobotHeroCard(
                mood: mood,
                onTap: onFullScreenTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
