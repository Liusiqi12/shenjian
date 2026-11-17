import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'record_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppState state = AppState.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: state,
          builder: (context, _) {
            return Column(
              children: [
                _topBar(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: _stats(),
                ),
                Expanded(child: _list()),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _micButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: kInk,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.graphic_eq, size: 16, color: Color(0xFFF2B48C)),
          ),
          const SizedBox(width: 9),
          Text('声笺', style: serifStyle(size: 23, weight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('VOICE NOTE', style: labelStyle(size: 10, spacing: 1.8)),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings_outlined, size: 20, color: kInkSoft),
            style: IconButton.styleFrom(
              backgroundColor: kCard.withOpacity(0.7),
              side: const BorderSide(color: kLineStrong),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    final items = <List<String>>[
      ['${state.todayCount}', '今日条数'],
      ['${state.notes.length}', '累计记录'],
      ['${state.settings.targets.length}', '目标语言'],
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: kCard.withOpacity(0.72),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: kLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(items[i][0],
                      style: serifStyle(size: 19, weight: FontWeight.w600, height: 1.2)),
                  const SizedBox(height: 2),
                  Text(items[i][1], style: labelStyle(size: 10.5, spacing: 1)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _list() {
    final notes = state.notes;
    if (notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kLineStrong),
                ),
                child: const Icon(Icons.mic_none, size: 30, color: kMuted),
              ),
              const SizedBox(height: 16),
              Text('还没有记录', style: serifStyle(size: 17)),
              const SizedBox(height: 6),
              Text(
                '点下面的按钮，说一句想说的话。\n说完它就成了文字，还能换成别的语言读出来。',
                textAlign: TextAlign.center,
                style: labelStyle(size: 12.5, spacing: 0.4),
              ),
            ],
          ),
        ),
      );
    }

    final rows = <Widget>[];
    String? lastDay;
    for (final n in notes) {
      final day = _dayKey(n.createdAt);
      if (day != lastDay) {
        lastDay = day;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
          child: Row(
            children: [
              Text(day, style: labelStyle(size: 11, spacing: 1.4)),
              const SizedBox(width: 10),
              const Expanded(child: Divider(height: 1, color: kLine)),
            ],
          ),
        ));
      }
      rows.add(_noteCard(n));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
      children: rows,
    );
  }

  Widget _noteCard(Note n) {
    final targets = state.settings.targets;
    final keys = n.translations.keys.toList()
      ..sort((a, b) {
        final ia = targets.indexOf(a), ib = targets.indexOf(b);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 8),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_timeLabel(n.createdAt), style: labelStyle(size: 11.5, spacing: 0.6)),
              const SizedBox(width: 8),
              if (n.durationSec > 0) _badge(_mmss(n.durationSec)),
              const Spacer(),
              Text(langOf(n.lang).shortName, style: labelStyle(size: 10.5, spacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            n.text.isEmpty ? '（没有识别到文字）' : n.text,
            style: serifStyle(size: 16.5, weight: FontWeight.w500, height: 1.75),
          ),
          for (final k in keys) _translationBlock(k, n.translations[k] ?? ''),
          if (n.translating)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('正在翻译…', style: labelStyle(size: 11, color: kMuted)),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                _action(Icons.play_arrow_outlined,
                    (n.audioPath != null && n.audioPath!.isNotEmpty) ? '听原声' : '朗读原文',
                    () => _speak(n, original: true)),
                _action(Icons.volume_up_outlined, '读译文', () => _speak(n)),
                _action(Icons.copy_outlined, '复制', () => _copy(n)),
                _action(Icons.delete_outline, '删除', () => _delete(n)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: kAccentSoft,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(text,
            style: labelStyle(size: 10, color: const Color(0xFF8A2F12), spacing: 0.4)),
      );

  Widget _translationBlock(String code, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Container(
        padding: const EdgeInsets.only(top: 9),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kLine, width: 0.8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              margin: const EdgeInsets.only(top: 2, right: 9),
              padding: const EdgeInsets.symmetric(vertical: 1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: kLineStrong),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(langOf(code).shortName,
                  style: labelStyle(size: 9.5, spacing: 0.8)),
            ),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13.5, height: 1.65, color: kInkSoft)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: kMuted),
              const SizedBox(width: 4),
              Text(label, style: labelStyle(size: 11.5, spacing: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _micButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecordPage()),
          );
          if (mounted) setState(() {});
        },
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: kInk,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Color(0x5917150F), blurRadius: 26, offset: Offset(0, 10)),
            ],
            border: Border.all(color: kCard, width: 5),
          ),
          child: const Icon(Icons.mic, color: kPaper, size: 30),
        ),
      ),
    );
  }

  Future<void> _speak(Note n, {bool original = false}) async {
    final s = state.settings;
    if (original) {
      await TtsService.speak(n.text, n.lang, s, audioPath: n.audioPath);
      return;
    }
    final first = s.targets.firstWhere(
      (t) => n.translations[t] != null && n.translations[t]!.isNotEmpty,
      orElse: () => '',
    );
    if (first.isEmpty) {
      await TtsService.speak(n.text, n.lang, s);
    } else {
      await TtsService.speak(n.translations[first]!, first, s);
    }
  }

  Future<void> _copy(Note n) async {
    final buf = StringBuffer(n.text);
    n.translations.forEach((k, v) {
      if (v.isNotEmpty) buf.write('\n[${langOf(k).shortName}] $v');
    });
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
    }
  }

  Future<void> _delete(Note n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('删除这条记录？', style: TextStyle(fontSize: 16)),
        content: Text(n.text, maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await state.deleteNote(n.id);
    }
  }

  static String _dayKey(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    return '${d.month}月${d.day}日';
  }

  static String _timeLabel(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _mmss(int sec) =>
      '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
}
