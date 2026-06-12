part of "../robot_control_page.dart";

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
