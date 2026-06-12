part of "../robot_control_page.dart";

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
