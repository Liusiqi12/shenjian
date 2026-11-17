import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models.dart';

/// 转写：设备内置识别（免费、实时）或自建 Whisper 兼容接口。
class AsrService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  String? lastError;

  bool get isListening => _speech.isListening;
  bool get isReady => _ready;

  Future<bool> ensureReady({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onStatus: (s) => onStatus?.call(s),
        onError: (e) {
          lastError = e.errorMsg;
          onError?.call(e.errorMsg);
        },
      );
    } catch (e) {
      lastError = '$e';
      _ready = false;
    }
    return _ready;
  }

  Future<void> start({
    required String localeId,
    required void Function(String words, bool isFinal) onResult,
    void Function(String status)? onStatus,
  }) async {
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      localeId: localeId,
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.dictation,
    );
  }

  Future<void> stop() => _speech.stop();
  Future<void> cancel() => _speech.cancel();

  /// 自建 Whisper 兼容接口（POST multipart，字段名 file）
  static Future<String> cloudTranscribe({
    required String filePath,
    required Settings s,
    required String langCode,
  }) async {
    if (s.asrUrl.isEmpty) throw Exception('还没配置转写接口');
    final req = http.MultipartRequest('POST', Uri.parse(s.asrUrl));
    if (s.asrKey.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer ${s.asrKey}';
    }
    req.fields['model'] = 'whisper-1';
    req.fields['language'] = langCode.split('-').first;
    req.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('HTTP ${streamed.statusCode}：${body.substring(0, body.length > 120 ? 120 : body.length)}');
    }
    final data = jsonDecode(body);
    final text = data is Map ? data['text'] : null;
    if (text is! String || text.trim().isEmpty) throw Exception('返回里没有文字');
    return text.trim();
  }

  static Future<int> fileSize(String path) async {
    final f = File(path);
    return f.existsSync() ? await f.length() : 0;
  }

  static String langOfCode(String code) => langOf(code).asrLocale;
}
