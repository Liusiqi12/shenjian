import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models.dart';

/// 朗读：系统音色，或调用你自己的声音克隆接口。
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static final AudioPlayer _player = AudioPlayer();
  static bool _configured = false;

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.setSpeechRate(1.0);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    _configured = true;
  }

  static Future<List<Map<String, String>>> voices() async {
    await _ensureConfigured();
    final raw = await _tts.getVoices;
    final out = <Map<String, String>>[];
    if (raw is List) {
      for (final v in raw) {
        if (v is Map) {
          out.add({
            'name': (v['name'] ?? '').toString(),
            'locale': (v['locale'] ?? '').toString(),
          });
        }
      }
    }
    return out;
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _player.stop();
    } catch (_) {}
  }

  static Future<void> speak(
    String text,
    String langCode,
    Settings s, {
    String? audioPath,
  }) async {
    if (audioPath != null && audioPath.isNotEmpty && File(audioPath).existsSync()) {
      await playFile(audioPath);
      return;
    }
    if (text.trim().isEmpty) return;
    if (s.ttsMode == 'clone' && s.cloneUrl.isNotEmpty) {
      await speakClone(text, langCode, s);
    } else {
      await speakSystem(text, langCode, voiceName: s.sysVoice);
    }
  }

  static Future<void> speakSystem(
    String text,
    String langCode, {
    String? voiceName,
  }) async {
    await _ensureConfigured();
    await _tts.stop();
    final locale = langOf(langCode).ttsLocale;
    await _tts.setLanguage(locale);
    if (voiceName != null && voiceName.isNotEmpty) {
      try {
        await _tts.setVoice({'name': voiceName, 'locale': locale});
      } catch (_) {}
    }
    await _tts.speak(text);
  }

  static Future<void> speakClone(String text, String langCode, Settings s) async {
    try {
      final res = await http
          .post(
            Uri.parse(s.cloneUrl),
            headers: {
              'Content-Type': 'application/json',
              if (s.cloneKey.isNotEmpty) 'Authorization': 'Bearer ${s.cloneKey}',
            },
            body: jsonEncode({
              'text': text,
              'language': langOf(langCode).code,
              'voice_id': s.cloneVoice,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final ct = (res.headers['content-type'] ?? '').toLowerCase();
      if (ct.contains('json')) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final b64 = (data is Map)
            ? (data['audio_base64'] ?? (data['data'] is Map ? data['data']['audio_base64'] : null))
            : null;
        if (b64 is String && b64.isNotEmpty) {
          final bytes = base64Decode(b64.replaceFirst(RegExp(r'^data:[^,]+,?'), ''));
          await _playBytes(bytes, 'mp3');
          return;
        }
        final url = (data is Map)
            ? (data['audio_url'] ?? (data['data'] is Map ? data['data']['audio_url'] : null))
            : null;
        if (url is String && url.isNotEmpty) {
          await _player.stop();
          await _player.play(UrlSource(url));
          return;
        }
        throw Exception('返回里没有音频');
      }

      await _playBytes(res.bodyBytes, _extFromMime(ct));
    } catch (e) {
      // 克隆服务不可用时退回系统音色，保证还能读出来
      await speakSystem(text, langCode);
      throw Exception('克隆音色失败，已用系统音色：$e');
    }
  }

  static Future<void> playFile(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  static Future<void> _playBytes(Uint8List bytes, String ext) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.$ext');
    await file.writeAsBytes(bytes);
    await _player.stop();
    await _player.play(DeviceFileSource(file.path));
  }

  static String _extFromMime(String ct) {
    if (ct.contains('wav')) return 'wav';
    if (ct.contains('mp4') || ct.contains('aac') || ct.contains('m4a')) return 'm4a';
    if (ct.contains('ogg')) return 'ogg';
    return 'mp3';
  }
}
