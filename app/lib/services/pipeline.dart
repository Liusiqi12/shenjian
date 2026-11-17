import '../app_state.dart';
import '../models.dart';
import 'translate_service.dart';

/// 给一条记录补齐所有目标语言的译文，边翻边存，界面实时刷新。
class Pipeline {
  static Future<void> translateNote(Note note) async {
    final state = AppState.instance;
    final s = state.settings;
    if (note.text.trim().isEmpty) return;

    note.translating = true;
    state.touch();

    for (final code in s.targets) {
      if (note.translations[code] != null && note.translations[code]!.isNotEmpty) {
        continue;
      }
      if (langOf(code).code.split('-').first == langOf(note.lang).code.split('-').first) {
        continue;
      }
      try {
        final t = await TranslateService.translate(note.text, note.lang, code, s);
        note.translations[code] = t;
      } catch (e) {
        note.translations[code] = '翻译失败（$e）';
      }
      await state.saveNotes();
    }

    note.translating = false;
    await state.saveNotes();
  }

  /// 启动时补翻历史记录里缺的译文
  static Future<void> backfill() async {
    final state = AppState.instance;
    for (final n in List<Note>.from(state.notes)) {
      final need = state.settings.targets.any(
        (t) => n.translations[t] == null || n.translations[t]!.isEmpty,
      );
      if (need && n.text.trim().isNotEmpty) {
        await translateNote(n);
      }
    }
  }
}
