import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/asr_service.dart';
import '../services/pipeline.dart';
import '../services/tts_service.dart';
import '../theme.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final AppState state = AppState.instance;
  final AudioRecorder _recorder = AudioRecorder();
  final AsrService _asr = AsrService();

  Timer? _ticker;
  DateTime? _startedAt;
  int _seconds = 0;
  bool _recording = false;
  bool _working = false;
  String _text = '';
  String? _audioPath;
  String _status = '正在准备麦克风…';
  String _meta = '录音结束后自动转写并翻译';

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _asr.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final s = state.settings;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (!mounted) return;
      setState(() {
        _status = '没有麦克风权限';
        _meta = '请在系统设置里允许麦克风；也可以直接手写一条';
      });
      return;
    }

    // 先录音频：即使识别不可用，也留一份原声
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/recordings');
      if (!folder.existsSync()) folder.createSync(recursive: true);
      final path = '${folder.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      _audioPath = path;
    } catch (e) {
      _audioPath = null;
    }

    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || _startedAt == null) return;
      setState(() => _seconds = DateTime.now().difference(_startedAt!).inSeconds);
      if (_seconds >= 600) _save();
    });

    if (!mounted) return;
    setState(() {
      _recording = true;
      _status = s.asrEngine == 'cloud' ? '正在录音（结束后转写）' : '正在听你说话';
      _meta = s.asrEngine == 'cloud' ? '停下来会用自建接口转写' : '抬头说，不用管停顿';
    });

    if (s.asrEngine == 'device') {
      final ok = await _asr.ensureReady(
        onError: (e) {
          if (!mounted) return;
          setState(() => _meta = '识别出错：$e');
        },
      );
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _status = '这台设备的语音识别不可用';
          _meta = '录音会保存，可手动补文字，或改用自建转写接口';
        });
        return;
      }
      await _asr.start(
        localeId: langOf(s.asrLang).asrLocale,
        onResult: (words, isFinal) {
          if (!mounted) return;
          setState(() => _text = words);
        },
      );
    }
  }

  Future<void> _save() async {
    if (_working) return;
    setState(() => _working = true);
    _ticker?.cancel();
    final s = state.settings;

    try {
      await _asr.stop();
    } catch (_) {}
    try {
      if (await _recorder.isRecording()) await _recorder.stop();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _recording = false);

    // 自建接口：拿录音去转写
    if (s.asrEngine == 'cloud' && _text.trim().isEmpty && _audioPath != null) {
      setState(() => _status = '正在转写…');
      try {
        _text = await AsrService.cloudTranscribe(
          filePath: _audioPath!,
          s: s,
          langCode: s.asrLang,
        );
      } catch (e) {
        setState(() => _meta = '转写失败：$e');
      }
    }

    var content = _text.trim();
    if (content.isEmpty) {
      final typed = await _askManualText();
      if (typed == null) {
        _discard();
        return;
      }
      content = typed;
    }

    final note = Note(
      id: AppState.newId(),
      createdAt: DateTime.now(),
      durationSec: _seconds,
      lang: s.asrLang,
      text: content,
      audioPath: _audioPath,
    );
    await state.addNote(note);
    Pipeline.translateNote(note);

    if (s.autoSpeak && s.targets.isNotEmpty) {
      final first = s.targets.first;
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        final v = note.translations[first];
        if (v != null && v.isNotEmpty) {
          TtsService.speak(v, first, s);
        } else {
          TtsService.speak(note.text, note.lang, s, audioPath: note.audioPath);
        }
      });
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<String?> _askManualText() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('没有识别到文字', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 2,
          decoration: const InputDecoration(
            hintText: '手动写一条，或者取消',
            hintStyle: TextStyle(color: kMuted, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return null;
    return result;
  }

  void _discard() {
    if (_audioPath != null) {
      try {
        final f = File(_audioPath!);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _cancel() async {
    _ticker?.cancel();
    try {
      await _asr.cancel();
    } catch (_) {}
    try {
      if (await _recorder.isRecording()) await _recorder.stop();
    } catch (_) {}
    _discard();
  }

  void _switchLang(String code) {
    setState(() => state.settings.asrLang = code);
    state.saveSettings();
    if (_recording && state.settings.asrEngine == 'device') {
      _asr.cancel().then((_) {
        _asr.start(
          localeId: langOf(code).asrLocale,
          onResult: (words, isFinal) {
            if (!mounted) return;
            setState(() => _text = words);
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quick = <String>['zh-CN', 'en', 'ja', 'ko', 'es', 'fr', 'de', 'ru'];
    final current = state.settings.asrLang;
    final langs = <String>[
      for (final c in quick) if (c != current) c,
      current,
    ];

    return Scaffold(
      backgroundColor: kPaper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 0),
              child: Row(
                children: [
                  Text(_recording ? '录音中' : '已停止',
                      style: labelStyle(size: 11, spacing: 2)),
                  const Spacer(),
                  TextButton(
                    onPressed: _working ? null : _cancel,
                    child: Text('取消', style: labelStyle(size: 12.5, spacing: 0.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(_mmss(_seconds), style: serifStyle(size: 34, weight: FontWeight.w600, height: 1.3)),
            const SizedBox(height: 2),
            Text(_status, style: labelStyle(size: 11, spacing: 1.6)),
            const SizedBox(height: 16),
            _Waveform(active: _recording),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final c in langs)
                  _langChip(c, c == current, () => _switchLang(c)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                child: _text.trim().isEmpty
                    ? Text(
                        '直接开口说吧，边说话边变成文字。说完点下面的按钮保存。',
                        style: labelStyle(size: 13, spacing: 0.4),
                      )
                    : Text(_text, style: serifStyle(size: 16, weight: FontWeight.w500, height: 1.85)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(_meta, style: labelStyle(size: 11, spacing: 0.4)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _working ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: kInk,
                    foregroundColor: kPaper,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_working ? '处理中…' : '说完，保存',
                      style: const TextStyle(fontSize: 15, letterSpacing: 1.6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _langChip(String code, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: on ? kInk : kCard.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? kInk : kLineStrong),
        ),
        child: Text(
          langOf(code).shortName,
          style: TextStyle(fontSize: 11.5, color: on ? kPaper : kInkSoft, letterSpacing: 0.5),
        ),
      ),
    );
  }

  static String _mmss(int sec) =>
      '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
}

class _Waveform extends StatefulWidget {
  const _Waveform({required this.active});
  final bool active;

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant _Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(27, (i) {
              final phase = i * 0.55;
              final amp = widget.active
                  ? 0.22 + 0.78 * (0.5 + 0.5 * math.sin(_c.value * math.pi * 4 + phase)) *
                      math.sin((i / 26) * math.pi)
                  : 0.16;
              return Container(
                width: 3,
                height: 5 + 36 * amp,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(widget.active ? 0.72 : 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
