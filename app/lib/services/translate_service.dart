import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

/// 翻译：先走自建接口（如果配了），再依次降级到两个免费公共接口。
class TranslateService {
  static const Duration _timeout = Duration(seconds: 12);

  static Future<String> translate(
    String text,
    String from,
    String to,
    Settings s,
  ) async {
    final clean = text.trim();
    if (clean.isEmpty) return '';
    if (langOf(from).code.split('-').first == langOf(to).code.split('-').first) {
      return clean;
    }

    final errors = <String>[];

    if (s.trEngine == 'custom' && s.trUrl.isNotEmpty) {
      try {
        return await _custom(clean, from, to, s);
      } catch (e) {
        errors.add('自建接口 $e');
      }
    }

    try {
      return await _google(clean, from, to);
    } catch (e) {
      errors.add('gtx $e');
    }

    try {
      return await _myMemory(clean, from, to);
    } catch (e) {
      errors.add('mymemory $e');
    }

    if (s.trUrl.isNotEmpty && s.trEngine != 'custom') {
      try {
        return await _custom(clean, from, to, s);
      } catch (e) {
        errors.add('自建接口 $e');
      }
    }

    throw Exception(errors.join(' / '));
  }

  static Future<String> _google(String text, String from, String to) async {
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single'
      '?client=gtx&sl=${Uri.encodeComponent(langOf(from).code)}'
      '&tl=${Uri.encodeComponent(langOf(to).code)}&dt=t'
      '&q=${Uri.encodeComponent(text)}',
    );
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final segs = (data is List && data.isNotEmpty) ? data[0] : null;
    if (segs is! List) throw Exception('返回格式不认识');
    final buf = StringBuffer();
    for (final seg in segs) {
      if (seg is List && seg.isNotEmpty && seg[0] is String) {
        buf.write(seg[0] as String);
      }
    }
    final out = buf.toString().trim();
    if (out.isEmpty) throw Exception('返回为空');
    return out;
  }

  static Future<String> _myMemory(String text, String from, String to) async {
    final clipped = text.length > 480 ? text.substring(0, 480) : text;
    final uri = Uri.parse(
      'https://api.mymemory.translated.net/get'
      '?q=${Uri.encodeComponent(clipped)}'
      '&langpair=${Uri.encodeComponent('${langOf(from).code}|${langOf(to).code}')}',
    );
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final v = data is Map ? data['responseData']?['translatedText'] : null;
    if (v is! String || v.isEmpty) throw Exception('返回为空');
    if (v.contains('MYMEMORY WARNING') || v.contains('QUERY LENGTH LIMIT')) {
      throw Exception('额度限制');
    }
    return v.trim();
  }

  static Future<String> _custom(
    String text,
    String from,
    String to,
    Settings s,
  ) async {
    final body = <String, dynamic>{
      'model': s.trModel.isEmpty ? 'gpt-4o-mini' : s.trModel,
      'temperature': 0.2,
      'messages': [
        {
          'role': 'system',
          'content': '你是一名专业翻译。把用户给出的文本翻译成目标语言，'
              '只输出译文本身，不要解释、不要加引号，保留原有语气和换行。'
              '目标语言：${langOf(to).name}（${langOf(to).code}）。'
              '源语言：${langOf(from).name}。',
        },
        {'role': 'user', 'content': text},
      ],
    };
    final res = await http
        .post(
          Uri.parse(s.trUrl),
          headers: {
            'Content-Type': 'application/json',
            if (s.trKey.isNotEmpty) 'Authorization': 'Bearer ${s.trKey}',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final v = data is Map
        ? data['choices']?[0]?['message']?['content']
        : null;
    if (v is! String || v.trim().isEmpty) throw Exception('返回为空');
    return v.trim();
  }
}
