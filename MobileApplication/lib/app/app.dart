import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/BT_HardwareDrive/bluetooth_device_info.dart';
import 'features/bluetooth/models/companion_connect_state.dart';
import 'features/bluetooth/pages/robot_bluetooth_page.dart';
import 'features/bot_control/models/companion_move_command.dart';
import 'features/bot_control/pages/robot_control_page.dart';
import 'features/robot_face/models/companion_bot_mood.dart';
import 'features/robot_face/pages/immersive_robot_page.dart';
import 'features/robot_face/pages/robot_home_page.dart';
import 'features/settings/models/robot_settings.dart';
import 'features/settings/pages/robot_settings_page.dart';
import 'router/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/floating_bottom_bar.dart';
import 'shared/widgets/menu/app_menu_models.dart';

class MiloAiApp extends StatelessWidget
//你知道这里为什么是Class MiloAiApp吗，因为Milo是Mota的亲姐姐
//但是Milo已经未发布就死于胎中，扣111复活Milo，顺带纪念Milo
{
  const MiloAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milo-AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const CompanionRobotApp(),
    );
  }
}

class CompanionRobotApp extends StatefulWidget {
  const CompanionRobotApp({super.key});

  @override
  State<CompanionRobotApp> createState() => _CompanionRobotAppState();
}

class _CompanionRobotAppState extends State<CompanionRobotApp> {
  static const String _nicknameKey = 'menu_profile_nickname';
  static const String _avatarEmojiKey = 'menu_profile_avatar_emoji';
  static const String _avatarImageKey = 'menu_profile_avatar_image';

  CompanionBotMood _mood = CompanionBotMood.neutral;
  CompanionConnectState _connectState = CompanionConnectState.disconnected;
  RobotSettings _settings = const RobotSettings();
  MenuProfileState _profile = const MenuProfileState(
    nickname: 'Lin Robot 用户',
    avatarEmoji: '🤖',
  );
  RobotTab _currentTab = RobotTab.home;
  String _lastCommand = '暂无指令';
  String _aiMessage = '点击 AI 呼唤，可以模拟让机器人来到你身边。';
  int _bluetoothScanRequest = 0;
  bool _showFullScreenFace = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_showFullScreenFace) {
      return ImmersiveRobotPage(
        mood: _mood,
        onExit: () => setState(() => _showFullScreenFace = false),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildCurrentPage(),
            Align(
              alignment: Alignment.bottomCenter,
              child: FloatingBottomBar(
                currentTab: _currentTab,
                onTabChange: (tab) => setState(() => _currentTab = tab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    return switch (_currentTab) {
      RobotTab.home => RobotHomePage(
          mood: _mood,
          connectState: _connectState,
          lastCommand: _lastCommand,
          aiMessage: _aiMessage,
          onMoodChange: (mood) => setState(() => _mood = mood),
          onFullScreenTap: () => setState(() => _showFullScreenFace = true),
          onAiCallTap: _aiCall,
          onScanTap: _openBluetoothScanner,
          onConnectTap: _quickConnect,
        ),
      RobotTab.move => RobotControlPage(
          connectState: _connectState,
          mood: _mood,
          lastCommand: _lastCommand,
          aiMessage: _aiMessage,
          onMoodChange: (mood) => setState(() => _mood = mood),
          onScanTap: _openBluetoothScanner,
          onConnectTap: _quickConnect,
          onDisconnectTap: _disconnect,
          onMoveCommand: _moveRobot,
        ),
      RobotTab.bluetooth => RobotBluetoothPage(
          connectState: _connectState,
          scanRequestId: _bluetoothScanRequest,
          onScanStarted: _scanStarted,
          onDeviceConnected: _deviceConnected,
          onDisconnectTap: _disconnect,
        ),
      RobotTab.settings => RobotSettingsPage(
          connectState: _connectState,
          settings: _settings,
          profile: _profile,
          onSettingsChanged: _settingsChanged,
          onProfileChanged: _profileChanged,
        ),
    };
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final image = prefs.getString(_avatarImageKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = MenuProfileState(
        nickname: prefs.getString(_nicknameKey) ?? _profile.nickname,
        avatarEmoji: prefs.getString(_avatarEmojiKey) ?? _profile.avatarEmoji,
        avatarImageBytes: image == null ? null : base64Decode(image),
      );
    });
  }

  Future<void> _profileChanged(MenuProfileState profile) async {
    setState(() => _profile = profile);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, profile.nickname);
    await prefs.setString(_avatarEmojiKey, profile.avatarEmoji);

    final imageBytes = profile.avatarImageBytes;
    if (imageBytes == null) {
      await prefs.remove(_avatarImageKey);
      return;
    }

    await prefs.setString(_avatarImageKey, base64Encode(imageBytes));
  }

  void _settingsChanged(RobotSettings settings) {
    setState(() => _settings = settings);
  }

  void _openBluetoothScanner() {
    setState(() {
      _currentTab = RobotTab.bluetooth;
      _bluetoothScanRequest += 1;
    });
  }

  void _scanStarted() {
    setState(() {
      _connectState = CompanionConnectState.scanning;
      _lastCommand = '正在扫描附近蓝牙机器人';
      _aiMessage = '已开始扫描：LinBot-01 / Robot-01 / DemoBot';
    });
  }

  void _quickConnect() {
    setState(() {
      _connectState = CompanionConnectState.connected;
      _mood = CompanionBotMood.happy;
      _lastCommand = '已连接 LinBot-01';
      _aiMessage = '连接成功，当前是前端模拟连接。后续可以接真实蓝牙。';
    });
  }

  void _deviceConnected(BluetoothDeviceInfo device) {
    setState(() {
      _connectState = CompanionConnectState.connected;
      _mood = CompanionBotMood.happy;
      _lastCommand = '已连接 ${device.name}';
      _aiMessage = '已选择蓝牙设备：${device.name}。后续接入真实机器人协议后可在这里发送控制指令。';
    });
  }

  void _disconnect() {
    setState(() {
      _connectState = CompanionConnectState.disconnected;
      _mood = CompanionBotMood.neutral;
      _lastCommand = '已断开连接';
      _aiMessage = '机器人已断开连接。';
    });
  }

  void _aiCall() {
    setState(() {
      _mood = CompanionBotMood.love;
      _lastCommand = 'AI 呼唤：到我旁边';
      _aiMessage = _connectState == CompanionConnectState.connected
          ? '收到呼唤：机器人正在向你靠近。'
          : '已模拟呼唤，但当前还没有连接真实蓝牙机器人。';
    });
  }

  void _moveRobot(CompanionMoveCommand command) {
    setState(() {
      _lastCommand = '移动指令：${command.title}';
      _mood = switch (command) {
        CompanionMoveCommand.comeHere => CompanionBotMood.love,
        CompanionMoveCommand.forward => CompanionBotMood.happy,
        CompanionMoveCommand.backward => CompanionBotMood.surprised,
        CompanionMoveCommand.left => CompanionBotMood.neutral,
        CompanionMoveCommand.right => CompanionBotMood.neutral,
        CompanionMoveCommand.stop => CompanionBotMood.sleepy,
      };
      _aiMessage = '已发送前端指令：${command.title}。后续这里接蓝牙控制。';
    });
  }
}
