// livekit_token_generator.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class LiveKitTokenGenerator {
  // ⚠️ ضع مفاتيح LiveKit الحقيقية هنا (من Dashboard)
  static const String apiKey = "APIYPoXPHJtZwAF";
  static const String apiSecret = "W2833ayx8Luh2Vg8okyuLfQuLUA2QkuAJi8WBRuFnbP";
  static const String serverUrl = "wss://project-3almashe-run-ai23cs02.livekit.cloud";

  static String generateToken({
    required String roomName,
    required String participantName,
    int ttlSeconds = 3600,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final exp = now + ttlSeconds;

    final header = {
      "alg": "HS256",
      "typ": "JWT",
    };

    final payload = {
      "iss": apiKey,
      "name": participantName,
      "video": {
        "room": roomName,
        "roomJoin": true,
        "canPublish": true,
        "canSubscribe": true,
        "canPublishData": true,
      },
      "exp": exp,
      "nbf": now,
      "sub": participantName,
    };

    final encodedHeader = _base64UrlEncode(utf8.encode(jsonEncode(header)));
    final encodedPayload = _base64UrlEncode(utf8.encode(jsonEncode(payload)));
    final signature = _hmacSha256("$encodedHeader.$encodedPayload", apiSecret);

    return "$encodedHeader.$encodedPayload.$signature";
  }

  static String _base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _hmacSha256(String data, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return base64Url.encode(digest.bytes);
  }
}