import 'package:flutter/material.dart';

import '../../../features/bluetooth/models/companion_connect_state.dart';
import '../../../features/robot_face/models/companion_bot_mood.dart';
import '../../../shared/theme/app_colors.dart';
import '../models/companion_move_command.dart';

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

class _ControlHeader extends StatelessWidget {
  const _ControlHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Robot Hub',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '状态、表情与移动控制',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('🤖', style: TextStyle(fontSize: 24)),
        ),
      ],
    );
  }
}

class _RobotStatusHero extends StatelessWidget {
  const _RobotStatusHero({
    required this.connectState,
    required this.mood,
    required this.onScanTap,
    required this.onConnectTap,
    required this.onDisconnectTap,
  });

  final CompanionConnectState connectState;
  final CompanionBotMood mood;
  final VoidCallback onScanTap;
  final VoidCallback onConnectTap;
  final VoidCallback onDisconnectTap;

  bool get _connected => connectState == CompanionConnectState.connected;
  bool get _scanning => connectState == CompanionConnectState.scanning;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(38),
      elevation: 12,
      shadowColor: AppColors.ink.withValues(alpha: 0.24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F2937), Color(0xFF0B1220)],
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _HeroRobotAvatar(mood: mood),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Milo Companion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _connected
                            ? '在线陪伴中，可以发送移动和表情指令'
                            : _scanning
                                ? '正在查找附近蓝牙机器人'
                                : '连接蓝牙机器人后开启陪伴模式',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.64),
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _OnlineBadge(connected: _connected, scanning: _scanning),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _HeroMetric(
                  label: 'Battery',
                  value: _connected ? '86%' : '--',
                  icon: Icons.battery_5_bar_rounded,
                ),
                const SizedBox(width: 10),
                _HeroMetric(
                  label: 'Mood',
                  value: mood.title,
                  icon: Icons.auto_awesome_rounded,
                ),
                const SizedBox(width: 10),
                _HeroMetric(
                  label: 'State',
                  value: _connected
                      ? '在线'
                      : _scanning
                          ? '扫描'
                          : '待机',
                  icon: Icons.sensors_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _HeroActionButton(
                    text: '扫描机器人',
                    icon: Icons.radar_rounded,
                    onTap: onScanTap,
                    highlighted: !_connected,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroActionButton(
                    text: _connected ? '断开连接' : '快速连接',
                    icon: _connected
                        ? Icons.link_off_rounded
                        : Icons.link_rounded,
                    onTap: _connected ? onDisconnectTap : onConnectTap,
                    danger: _connected,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroRobotAvatar extends StatelessWidget {
  const _HeroRobotAvatar({required this.mood});

  final CompanionBotMood mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 38,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: mood.moodColor, width: 2),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RobotEye(color: mood.moodColor),
              const SizedBox(width: 8),
              _RobotEye(color: mood.moodColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _RobotEye extends StatelessWidget {
  const _RobotEye({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({
    required this.connected,
    required this.scanning,
  });

  final bool connected;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final bg = connected ? const Color(0xFF9BEA6A) : Colors.white24;
    final text = connected
        ? '在线'
        : scanning
            ? '扫描中'
            : '离线';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: connected ? const Color(0xFF15803D) : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: connected ? AppColors.ink : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 84,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.aqua),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.48),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
    this.danger = false,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final background = danger
        ? AppColors.orange
        : highlighted
            ? AppColors.lime
            : Colors.white.withValues(alpha: 0.14);
    final foreground = highlighted ? AppColors.ink : Colors.white;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 19,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MoodSelector extends StatelessWidget {
  const _MoodSelector({
    required this.currentMood,
    required this.onMoodChange,
  });

  final CompanionBotMood currentMood;
  final ValueChanged<CompanionBotMood> onMoodChange;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: CompanionBotMood.values.map((item) {
            final selected = item == currentMood;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected ? item.moodColor : AppColors.cardSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onMoodChange(item),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  child: Text(
                    '${item.emoji} ${item.title}',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MovementPanel extends StatelessWidget {
  const _MovementPanel({required this.onMoveCommand});

  final ValueChanged<CompanionMoveCommand> onMoveCommand;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(34),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.09),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _WideCommandButton(
              label: '到我旁边',
              icon: Icons.favorite_rounded,
              color: AppColors.orange,
              onTap: () => onMoveCommand(CompanionMoveCommand.comeHere),
            ),
            const SizedBox(height: 14),
            _DirectionButton(
              icon: Icons.keyboard_arrow_up_rounded,
              label: '前进',
              onTap: () => onMoveCommand(CompanionMoveCommand.forward),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DirectionButton(
                    icon: Icons.keyboard_arrow_left_rounded,
                    label: '左转',
                    onTap: () => onMoveCommand(CompanionMoveCommand.left),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DirectionButton(
                    icon: Icons.pause_rounded,
                    label: '停止',
                    danger: true,
                    onTap: () => onMoveCommand(CompanionMoveCommand.stop),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DirectionButton(
                    icon: Icons.keyboard_arrow_right_rounded,
                    label: '右转',
                    onTap: () => onMoveCommand(CompanionMoveCommand.right),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DirectionButton(
              icon: Icons.keyboard_arrow_down_rounded,
              label: '后退',
              onTap: () => onMoveCommand(CompanionMoveCommand.backward),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideCommandButton extends StatelessWidget {
  const _WideCommandButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 21),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final background = danger ? const Color(0xFFFFEEF0) : AppColors.cardSoft;
    final foreground = danger ? AppColors.danger : AppColors.ink;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 24),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({
    required this.connected,
    required this.scanning,
    required this.mood,
    required this.lastCommand,
    required this.aiMessage,
  });

  final bool connected;
  final bool scanning;
  final CompanionBotMood mood;
  final String lastCommand;
  final String aiMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.battery_5_bar_rounded,
                title: '电量',
                value: connected ? '86%' : '--',
                accent: connected ? const Color(0xFF22C55E) : AppColors.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                icon: Icons.bluetooth_connected_rounded,
                title: '蓝牙',
                value: connected
                    ? '已连接'
                    : scanning
                        ? '扫描中'
                        : '未连接',
                accent: connected ? const Color(0xFF22C55E) : AppColors.aqua,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.emoji_emotions_rounded,
                title: '表情',
                value: mood.title,
                accent: mood.moodColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                icon: Icons.favorite_rounded,
                title: '互动',
                value: connected ? '陪伴中' : '待机',
                accent: AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _WideInfoCard(
          icon: Icons.speaker_notes_rounded,
          title: '最近指令',
          value: lastCommand,
          subtitle: aiMessage,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideInfoCard extends StatelessWidget {
  const _WideInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.coralSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.orange, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
