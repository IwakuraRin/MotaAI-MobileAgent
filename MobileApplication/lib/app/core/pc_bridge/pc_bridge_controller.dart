// 文件作用：管理 MotaLink Agent 的连接状态、CLI 会话和终端输出。

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'pc_bridge_client.dart';
import 'pc_bridge_message.dart';
import 'pc_bridge_settings_store.dart';

enum PcBridgeConnectionState {
  disconnected,
  connecting,
  connected,
}

class PcBridgeController extends ChangeNotifier {
  PcBridgeController({
    PcBridgeSettingsStore? settingsStore,
  }) : _settingsStore = settingsStore ?? PcBridgeSettingsStore();

  final PcBridgeSettingsStore _settingsStore;
  PcBridgeSettings _settings = PcBridgeSettings.defaults();
  final List<String> _terminalLines = <String>[];

  PcBridgeClient? _client;
  StreamSubscription<PcBridgeMessage>? _messageSubscription;
  PcBridgeConnectionState _connectionState =
      PcBridgeConnectionState.disconnected;
  String? _sessionId;
  String? _errorText;
  bool _settingsLoaded = false;
  bool _creatingSession = false;

  PcBridgeSettings get settings => _settings;
  PcBridgeConnectionState get connectionState => _connectionState;
  String? get sessionId => _sessionId;
  String? get errorText => _errorText;
  bool get settingsLoaded => _settingsLoaded;
  bool get creatingSession => _creatingSession;
  bool get isConnected => _connectionState == PcBridgeConnectionState.connected;
  bool get hasSession => _sessionId != null;
  List<String> get terminalLines => List.unmodifiable(_terminalLines);

  Future<void> loadSettings() async {
    if (_settingsLoaded) {
      return;
    }

    _settings = await _settingsStore.readSettings();
    _settingsLoaded = true;
    notifyListeners();
  }

  Future<void> saveSettings(PcBridgeSettings settings) async {
    _settings = settings;
    await _settingsStore.writeSettings(settings);
    _settingsLoaded = true;
    _clearError();
    notifyListeners();
  }

  Future<void> connect() async {
    await loadSettings();
    if (!_settings.canConnect) {
      _setError('请填写 PC 地址、端口和连接 Token');
      return;
    }

    await disconnect();
    _connectionState = PcBridgeConnectionState.connecting;
    _clearError();
    notifyListeners();

    try {
      final client = PcBridgeClient.connect(_settings);
      _client = client;
      _messageSubscription = client.messages.listen(
        _handleMessage,
        onError: (_) => _handleDisconnected('MotaLink Agent 连接失败'),
        onDone: () => _handleDisconnected(null),
        cancelOnError: true,
      );
      _connectionState = PcBridgeConnectionState.connected;
      _appendTerminalLine('已连接 MotaLink Agent\n');
    } catch (_) {
      _connectionState = PcBridgeConnectionState.disconnected;
      _setError('MotaLink Agent 连接失败');
    }

    notifyListeners();
  }

  Future<void> disconnect() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    final client = _client;
    _client = null;
    _sessionId = null;
    _creatingSession = false;
    _connectionState = PcBridgeConnectionState.disconnected;
    if (client != null) {
      await client.close();
    }
    notifyListeners();
  }

  void createSession({int cols = 100, int rows = 30}) {
    final client = _client;
    if (client == null || !isConnected) {
      _setError('请先连接 MotaLink Agent');
      return;
    }
    if (!_settings.canCreateSession) {
      _setError('请填写 CLI 和工作目录');
      return;
    }

    _creatingSession = true;
    _clearError();
    notifyListeners();
    client.createSession(
      requestId: _createRequestId(),
      cli: _settings.cli.trim(),
      cwd: _settings.cwd.trim(),
      cols: cols,
      rows: rows,
    );
  }

  void sendInput(String rawText) {
    final text = rawText.trimRight();
    final client = _client;
    final sessionId = _sessionId;
    if (client == null || sessionId == null) {
      _setError('请先创建 CLI 会话');
      return;
    }
    if (text.trim().isEmpty) {
      return;
    }

    client.sendInput(sessionId: sessionId, text: '$text\n');
  }

  void interruptSession() {
    _sendSignal('interrupt');
  }

  void terminateSession() {
    _sendSignal('terminate');
  }

  void clearTerminal() {
    _terminalLines.clear();
    notifyListeners();
  }

  void _sendSignal(String signal) {
    final client = _client;
    final sessionId = _sessionId;
    if (client == null || sessionId == null) {
      _setError('请先创建 CLI 会话');
      return;
    }
    client.sendSignal(sessionId: sessionId, signal: signal);
  }

  void _handleMessage(PcBridgeMessage message) {
    switch (message.type) {
      case 'session.created':
        _sessionId = message.sessionId;
        _creatingSession = false;
        _appendTerminalLine('已创建 ${_settings.cli} 会话\n');
      case 'session.output':
        _appendTerminalLine(message.text ?? '');
      case 'session.exit':
        _appendTerminalLine('会话已退出，退出码 ${message.exitCode ?? 0}\n');
        _sessionId = null;
        _creatingSession = false;
      case 'error':
        _creatingSession = false;
        _setError(message.message ?? 'MotaLink Agent 返回错误');
      default:
        break;
    }
    notifyListeners();
  }

  void _handleDisconnected(String? message) {
    _connectionState = PcBridgeConnectionState.disconnected;
    _sessionId = null;
    _creatingSession = false;
    if (message != null) {
      _errorText = message;
      _appendTerminalLine('$message\n');
    }
    notifyListeners();
  }

  void _appendTerminalLine(String text) {
    if (text.isEmpty) {
      return;
    }

    _terminalLines.add(text);
    if (_terminalLines.length > 220) {
      _terminalLines.removeRange(0, _terminalLines.length - 220);
    }
  }

  void _setError(String message) {
    _errorText = message;
    _appendTerminalLine('$message\n');
    notifyListeners();
  }

  void _clearError() {
    _errorText = null;
  }

  String _createRequestId() {
    return 'req_${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _client?.close();
    super.dispose();
  }
}
