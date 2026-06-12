import 'package:flutter/material.dart';

import '../../../features/bluetooth/models/companion_connect_state.dart';
import '../../../features/robot_face/models/companion_bot_mood.dart';
import '../../../shared/theme/app_colors.dart';
import '../models/companion_move_command.dart';

part "widgets/control_header.dart";
part "widgets/robot_status_hero.dart";
part "widgets/mood_selector.dart";
part "widgets/movement_panel.dart";
part "widgets/status_grid.dart";

class RobotControlPage extends StatelessWidget {
  const RobotControlPage({
    required this.connectState,
    required this.mood,
    required this.lastCommand,
    required this.aiMessage,
    required this.onMoodChange,
    required this.onScanTap,
    required this.onConnectTap,
    required this.onDisconnectTap,
    required this.onMoveCommand,
    super.key,
  });

  final CompanionConnectState connectState;
  final CompanionBotMood mood;
  final String lastCommand;
  final String aiMessage;
  final ValueChanged<CompanionBotMood> onMoodChange;
  final VoidCallback onScanTap;
  final VoidCallback onConnectTap;
  final VoidCallback onDisconnectTap;
  final ValueChanged<CompanionMoveCommand> onMoveCommand;

  bool get _connected => connectState == CompanionConnectState.connected;
  bool get _scanning => connectState == CompanionConnectState.scanning;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 172),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ControlHeader(),
                  const SizedBox(height: 22),
                  _RobotStatusHero(
                    connectState: connectState,
                    mood: mood,
                    onScanTap: onScanTap,
                    onConnectTap: onConnectTap,
                    onDisconnectTap: onDisconnectTap,
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle('表情陪伴'),
                  const SizedBox(height: 10),
                  _MoodSelector(currentMood: mood, onMoodChange: onMoodChange),
                  const SizedBox(height: 18),
                  const _SectionTitle('移动控制'),
                  const SizedBox(height: 10),
                  _MovementPanel(onMoveCommand: onMoveCommand),
                  const SizedBox(height: 18),
                  const _SectionTitle('机器人状态'),
                  const SizedBox(height: 10),
                  _StatusGrid(
                    connected: _connected,
                    scanning: _scanning,
                    mood: mood,
                    lastCommand: lastCommand,
                    aiMessage: aiMessage,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
