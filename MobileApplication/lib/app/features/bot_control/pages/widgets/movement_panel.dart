part of "../robot_control_page.dart";

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
