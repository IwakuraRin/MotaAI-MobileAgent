// 文件作用：定义 Mota 与 MotaLink Agent 之间的 WebSocket JSON 协议消息。

import 'dart:convert';

class PcBridgeMessage {
  const PcBridgeMessage({
    required this.type,
    this.requestId,
    this.sessionId,
    this.text,
    this.message,
    this.exitCode,
  });

  factory PcBridgeMessage.fromJsonText(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Bridge message is not an object');
    }

    final type = decoded['type'];
    if (type is! String || type.trim().isEmpty) {
      throw const FormatException('Bridge message type is invalid');
    }

    return PcBridgeMessage(
      type: type,
      requestId: _readString(decoded['requestId']),
      sessionId: _readString(decoded['sessionId']),
      text: _readString(decoded['text']),
      message: _readString(decoded['message']),
      exitCode: _readInt(decoded['exitCode']),
    );
  }

  final String type;
  final String? requestId;
  final String? sessionId;
  final String? text;
  final String? message;
  final int? exitCode;
}

String encodePcBridgeMessage(Map<String, Object?> message) {
  return jsonEncode(
    Map<String, Object?>.fromEntries(
      message.entries.where((entry) => entry.value != null),
    ),
  );
}

String? _readString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return null;
}
