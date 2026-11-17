import 'dart:convert';

/// 支持的语言。code 用作设置里的稳定标识，asrLocale / ttsLocale 对应各平台要的格式。
class AppLanguage {
  final String code;
  final String name;
  final String shortName;
  final String asrLocale; // speech_to_text 用的 zh_CN 形式
  final String ttsLocale; // flutter_tts 用的 zh-CN 形式

  const AppLanguage(this.code, this.name, this.shortName,
      {required this.asrLocale, required this.ttsLocale});
}

const List<AppLanguage> kLanguages = <AppLanguage>[
  AppLanguage('zh-CN', '中文（普通话）', '中文', asrLocale: 'zh_CN', ttsLocale: 'zh-CN'),
  AppLanguage('en', 'English', 'EN', asrLocale: 'en_US', ttsLocale: 'en-US'),
  AppLanguage('ja', '日本語', '日本語', asrLocale: 'ja_JP', ttsLocale: 'ja-JP'),
  AppLanguage('ko', '한국어', '한국어', asrLocale: 'ko_KR', ttsLocale: 'ko-KR'),
  AppLanguage('es', 'Español', 'ES', asrLocale: 'es_ES', ttsLocale: 'es-ES'),
  AppLanguage('fr', 'Français', 'FR', asrLocale: 'fr_FR', ttsLocale: 'fr-FR'),
  AppLanguage('de', 'Deutsch', 'DE', asrLocale: 'de_DE', ttsLocale: 'de-DE'),
  AppLanguage('ru', 'Русский', 'RU', asrLocale: 'ru_RU', ttsLocale: 'ru-RU'),
  AppLanguage('pt', 'Português', 'PT', asrLocale: 'pt_BR', ttsLocale: 'pt-BR'),
  AppLanguage('ar', 'العربية', 'AR', asrLocale: 'ar_SA', ttsLocale: 'ar-SA'),
  AppLanguage('th', 'ไทย', 'TH', asrLocale: 'th_TH', ttsLocale: 'th-TH'),
  AppLanguage('vi', 'Tiếng Việt', 'VI', asrLocale: 'vi_VN', ttsLocale: 'vi-VN'),
  AppLanguage('it', 'Italiano', 'IT', asrLocale: 'it_IT', ttsLocale: 'it-IT'),
  AppLanguage('hi', 'हिन्दी', 'HI', asrLocale: 'hi_IN', ttsLocale: 'hi-IN'),
  AppLanguage('id', 'Bahasa Indonesia', 'ID', asrLocale: 'id_ID', ttsLocale: 'id-ID'),
  AppLanguage('tr', 'Türkçe', 'TR', asrLocale: 'tr_TR', ttsLocale: 'tr-TR'),
  AppLanguage('nl', 'Nederlands', 'NL', asrLocale: 'nl_NL', ttsLocale: 'nl-NL'),
  AppLanguage('pl', 'Polski', 'PL', asrLocale: 'pl_PL', ttsLocale: 'pl-PL'),
  AppLanguage('ms', 'Bahasa Melayu', 'MS', asrLocale: 'ms_MY', ttsLocale: 'ms-MY'),
];

AppLanguage langOf(String code) {
  for (final l in kLanguages) {
    if (l.code == code || l.code.split('-').first == code.split('-').first) return l;
  }
  return kLanguages.first;
}

/// 一条记录
class Note {
  final String id;
  final DateTime createdAt;
  final int durationSec;
  final String lang;
  String text;
  Map<String, String> translations;
  final String? audioPath;
  bool translating;

  Note({
    required this.id,
    required this.createdAt,
    required this.durationSec,
    required this.lang,
    required this.text,
    Map<String, String>? translations,
    this.audioPath,
    this.translating = false,
  }) : translations = translations ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'durationSec': durationSec,
        'lang': lang,
        'text': text,
        'translations': translations,
        'audioPath': audioPath,
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        durationSec: (j['durationSec'] as num?)?.toInt() ?? 0,
        lang: j['lang'] as String? ?? 'zh-CN',
        text: j['text'] as String? ?? '',
        translations: Map<String, String>.from(
            (j['translations'] as Map?)?.cast<String, String>() ?? const {}),
        audioPath: j['audioPath'] as String?,
      );
}

/// 全部设置
class Settings {
  String asrLang;
  List<String> targets;
  bool autoSpeak;

  // 转写引擎：device = 系统语音识别；cloud = 自建 Whisper 兼容接口
  String asrEngine;
  String asrUrl;
  String asrKey;

  // 翻译引擎：auto = 免费公共接口自动降级；custom = OpenAI 兼容接口
  String trEngine;
  String trUrl;
  String trKey;
  String trModel;

  // 朗读：system = 系统音色；clone = 我的克隆音色
  String ttsMode;
  String sysVoice;
  String cloneUrl;
  String cloneKey;
  String cloneVoice;

  Settings({
    this.asrLang = 'zh-CN',
    List<String>? targets,
    this.autoSpeak = false,
    this.asrEngine = 'device',
    this.asrUrl = '',
    this.asrKey = '',
    this.trEngine = 'auto',
    this.trUrl = '',
    this.trKey = '',
    this.trModel = '',
    this.ttsMode = 'system',
    this.sysVoice = '',
    this.cloneUrl = '',
    this.cloneKey = '',
    this.cloneVoice = '',
  }) : targets = targets ?? ['en'];

  Map<String, dynamic> toJson() => {
        'asrLang': asrLang,
        'targets': targets,
        'autoSpeak': autoSpeak,
        'asrEngine': asrEngine,
        'asrUrl': asrUrl,
        'asrKey': asrKey,
        'trEngine': trEngine,
        'trUrl': trUrl,
        'trKey': trKey,
        'trModel': trModel,
        'ttsMode': ttsMode,
        'sysVoice': sysVoice,
        'cloneUrl': cloneUrl,
        'cloneKey': cloneKey,
        'cloneVoice': cloneVoice,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        asrLang: j['asrLang'] as String? ?? 'zh-CN',
        targets: (j['targets'] as List?)?.cast<String>() ?? ['en'],
        autoSpeak: j['autoSpeak'] as bool? ?? false,
        asrEngine: j['asrEngine'] as String? ?? 'device',
        asrUrl: j['asrUrl'] as String? ?? '',
        asrKey: j['asrKey'] as String? ?? '',
        trEngine: j['trEngine'] as String? ?? 'auto',
        trUrl: j['trUrl'] as String? ?? '',
        trKey: j['trKey'] as String? ?? '',
        trModel: j['trModel'] as String? ?? '',
        ttsMode: j['ttsMode'] as String? ?? 'system',
        sysVoice: j['sysVoice'] as String? ?? '',
        cloneUrl: j['cloneUrl'] as String? ?? '',
        cloneKey: j['cloneKey'] as String? ?? '',
        cloneVoice: j['cloneVoice'] as String? ?? '',
      );
}

String prettyJson(Object o) => const JsonEncoder.withIndent('  ').convert(o);
