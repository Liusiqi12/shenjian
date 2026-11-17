import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// 全局状态：记录 + 设置，本地持久化。
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const String _kNotes = 'shenjian.notes.v1';
  static const String _kSettings = 'shenjian.settings.v1';

  SharedPreferences? _prefs;
  List<Note> notes = <Note>[];
  Settings settings = Settings();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final rawSettings = _prefs?.getString(_kSettings);
    if (rawSettings != null && rawSettings.isNotEmpty) {
      try {
        settings = Settings.fromJson(jsonDecode(rawSettings) as Map<String, dynamic>);
      } catch (_) {
        settings = Settings();
      }
    }
    final rawNotes = _prefs?.getString(_kNotes);
    if (rawNotes != null && rawNotes.isNotEmpty) {
      try {
        notes = (jsonDecode(rawNotes) as List)
            .map((e) => Note.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        notes = <Note>[];
      }
    }
    notifyListeners();
  }

  Future<void> saveSettings() async {
    await _prefs?.setString(_kSettings, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Future<void> saveNotes() async {
    await _prefs?.setString(
      _kNotes,
      jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    notes.insert(0, note);
    await saveNotes();
  }

  Future<void> deleteNote(String id) async {
    notes.removeWhere((n) => n.id == id);
    await saveNotes();
  }

  Future<void> clearAll() async {
    notes.clear();
    await saveNotes();
  }

  /// 生成一个短 id
  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
      (DateTime.now().millisecond % 1000).toString();

  /// 外部改完 Note 字段后手动通知界面刷新
  void touch() => notifyListeners();

  int get todayCount {
    final now = DateTime.now();
    return notes
        .where((n) =>
            n.createdAt.year == now.year &&
            n.createdAt.month == now.month &&
            n.createdAt.day == now.day)
        .length;
  }
}
