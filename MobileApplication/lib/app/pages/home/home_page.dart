import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
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
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: _HomeShortcutCard(
                      icon: Icons.chat_bubble_rounded,
                      title: '与Mota文本对话',
                      backgroundColor: AppColors.aquaSoft,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _HomeShortcutCard(
                      icon: Icons.devices_rounded,
                      title: '查看已连接设备',
                      compact: true,
                      backgroundColor: AppColors.coralSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeShortcutCard extends StatelessWidget {
  const _HomeShortcutCard({
    required this.icon,
    required this.title,
    required this.backgroundColor,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final Color backgroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(24),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.09),
      child: SizedBox(
        height: 86,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 16,
            vertical: 14,
          ),
          child: Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.ink, size: compact ? 20 : 24),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: compact ? 12 : 15,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
