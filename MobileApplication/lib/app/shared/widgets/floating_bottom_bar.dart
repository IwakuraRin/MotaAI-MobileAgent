// 文件作用：集中处理底部横向导航栏入口和触感反馈。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../../router/app_router.dart';

class FloatingBottomBar extends StatelessWidget {
  const FloatingBottomBar({
    required this.currentTab,
    required this.onTabChange,
    super.key,
  });

  final RobotTab currentTab;
  final ValueChanged<RobotTab> onTabChange;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.muted.withValues(alpha: 0.18)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 72,
          child: Row(
            children: RobotTab.values.map((tab) {
              return Expanded(
                child: BottomTabItem(
                  tab: tab,
                  selected: tab == currentTab,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTabChange(tab);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class BottomTabItem extends StatelessWidget {
  const BottomTabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final RobotTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                tab.iconAsset,
                width: 24,
                height: 24,
                color: selected ? AppColors.orange : AppColors.muted,
                colorBlendMode: BlendMode.srcIn,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.orange : AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
