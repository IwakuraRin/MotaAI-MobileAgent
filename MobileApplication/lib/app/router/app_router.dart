// 文件作用：集中定义底部导航 tab，避免页面索引和文案散落在多个文件里

enum RobotTab {
  chat('assets/icons/chat.png', '对话'),
  creativeWorkshop('assets/icons/creative_workshop.png', '创意工坊'),
  settings('assets/icons/settings.png', '设置');

  const RobotTab(this.iconAsset, this.label);

  final String iconAsset;
  final String label;
}
