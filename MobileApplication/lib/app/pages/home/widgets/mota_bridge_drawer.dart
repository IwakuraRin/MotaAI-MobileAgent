// 文件作用：提供 MotaLink Agent 的连接、会话创建和 CLI 输入输出面板。

import 'package:flutter/material.dart';

import '../../../core/pc_bridge/pc_bridge_controller.dart';
import '../../../core/pc_bridge/pc_bridge_settings_store.dart';
import '../../../shared/theme/app_colors.dart';

class MotaBridgeDrawer extends StatefulWidget {
  const MotaBridgeDrawer({
    required this.bridgeController,
    super.key,
  });

  final PcBridgeController bridgeController;

  @override
  State<MotaBridgeDrawer> createState() => _MotaBridgeDrawerState();
}

class _MotaBridgeDrawerState extends State<MotaBridgeDrawer> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _tokenController;
  late final TextEditingController _cliController;
  late final TextEditingController _cwdController;
  late final TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    final settings = widget.bridgeController.settings;
    _hostController = TextEditingController(text: settings.host);
    _portController = TextEditingController(text: settings.port.toString());
    _tokenController = TextEditingController(text: settings.token);
    _cliController = TextEditingController(text: settings.cli);
    _cwdController = TextEditingController(text: settings.cwd);
    _inputController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    _cliController.dispose();
    _cwdController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.52,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              elevation: 14,
              shadowColor: Colors.black.withValues(alpha: 0.18),
              clipBehavior: Clip.antiAlias,
              child: AnimatedBuilder(
                animation: widget.bridgeController,
                builder: (context, child) {
                  final controller = widget.bridgeController;
                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    children: [
                      Row(
                        children: [
                          const Text(
                            'PC Bridge',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          _BridgeStatusPill(state: controller.connectionState),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _BridgeTextField(
                        controller: _hostController,
                        labelText: 'PC 地址',
                        hintText: '192.168.1.23',
                        icon: Icons.computer_rounded,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _BridgeTextField(
                              controller: _portController,
                              labelText: '端口',
                              hintText: '8765',
                              icon: Icons.settings_ethernet_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BridgeTextField(
                              controller: _cliController,
                              labelText: 'CLI',
                              hintText: 'codex',
                              icon: Icons.terminal_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _BridgeTextField(
                        controller: _cwdController,
                        labelText: '工作目录',
                        hintText: '/Users/jhb/Desktop/Mota',
                        icon: Icons.folder_rounded,
                      ),
                      const SizedBox(height: 10),
                      _BridgeTextField(
                        controller: _tokenController,
                        labelText: 'Token',
                        hintText: 'MotaLink Agent token',
                        icon: Icons.key_rounded,
                        obscureText: true,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: controller.isConnected
                                ? null
                                : () => _saveAndConnect(),
                            icon: const Icon(Icons.link_rounded),
                            label: const Text('连接'),
                          ),
                          OutlinedButton.icon(
                            onPressed: controller.isConnected
                                ? () => widget.bridgeController.disconnect()
                                : null,
                            icon: const Icon(Icons.link_off_rounded),
                            label: const Text('断开'),
                          ),
                          OutlinedButton.icon(
                            onPressed: controller.isConnected &&
                                    !controller.hasSession &&
                                    !controller.creatingSession
                                ? () => _saveAndCreateSession()
                                : null,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('创建会话'),
                          ),
                        ],
                      ),
                      if (controller.errorText != null) ...[
                        const SizedBox(height: 12),
                        _BridgeErrorText(message: controller.errorText!),
                      ],
                      const SizedBox(height: 14),
                      _TerminalOutput(lines: controller.terminalLines),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _BridgeTextField(
                              controller: _inputController,
                              labelText: '输入',
                              hintText: '发送到当前 CLI 会话',
                              icon: Icons.keyboard_rounded,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendInput(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: '发送',
                            onPressed:
                                controller.hasSession ? _sendInput : null,
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: controller.hasSession
                                ? controller.interruptSession
                                : null,
                            icon:
                                const Icon(Icons.keyboard_control_key_rounded),
                            label: const Text('Ctrl+C'),
                          ),
                          OutlinedButton.icon(
                            onPressed: controller.hasSession
                                ? controller.terminateSession
                                : null,
                            icon: const Icon(Icons.stop_circle_rounded),
                            label: const Text('停止'),
                          ),
                          TextButton.icon(
                            onPressed: controller.terminalLines.isEmpty
                                ? null
                                : controller.clearTerminal,
                            icon: const Icon(Icons.cleaning_services_rounded),
                            label: const Text('清空'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadSettings() async {
    await widget.bridgeController.loadSettings();
    if (!mounted) {
      return;
    }

    final settings = widget.bridgeController.settings;
    _hostController.text = settings.host;
    _portController.text = settings.port.toString();
    _tokenController.text = settings.token;
    _cliController.text = settings.cli;
    _cwdController.text = settings.cwd;
  }

  Future<void> _saveAndConnect() async {
    await _saveSettings();
    await widget.bridgeController.connect();
  }

  Future<void> _saveAndCreateSession() async {
    await _saveSettings();
    widget.bridgeController.createSession();
  }

  Future<void> _saveSettings() {
    return widget.bridgeController.saveSettings(
      PcBridgeSettings(
        host: _hostController.text.trim(),
        port: int.tryParse(_portController.text.trim()) ?? 8765,
        token: _tokenController.text.trim(),
        cli: _cliController.text.trim(),
        cwd: _cwdController.text.trim(),
      ),
    );
  }

  void _sendInput() {
    final text = _inputController.text;
    if (text.trim().isEmpty) {
      return;
    }

    widget.bridgeController.sendInput(text);
    _inputController.clear();
  }
}

class _BridgeStatusPill extends StatelessWidget {
  const _BridgeStatusPill({required this.state});

  final PcBridgeConnectionState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      PcBridgeConnectionState.disconnected => '未连接',
      PcBridgeConnectionState.connecting => '连接中',
      PcBridgeConnectionState.connected => '已连接',
    };
    final color = switch (state) {
      PcBridgeConnectionState.disconnected => AppColors.muted,
      PcBridgeConnectionState.connecting => AppColors.orange,
      PcBridgeConnectionState.connected => AppColors.lime,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BridgeTextField extends StatelessWidget {
  const _BridgeTextField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enableSuggestions: !obscureText,
      autocorrect: !obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.orange, size: 20),
        filled: true,
        fillColor: AppColors.cardSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _TerminalOutput extends StatelessWidget {
  const _TerminalOutput({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.heroDeepBlack,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: Text(
          lines.isEmpty ? '等待 CLI 输出' : lines.join(''),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _BridgeErrorText extends StatelessWidget {
  const _BridgeErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: AppColors.danger,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
