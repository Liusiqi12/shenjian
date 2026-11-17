import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/tts_service.dart';
import '../theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppState state = AppState.instance;

  final _trUrl = TextEditingController();
  final _trKey = TextEditingController();
  final _trModel = TextEditingController();
  final _asrUrl = TextEditingController();
  final _asrKey = TextEditingController();
  final _cloneUrl = TextEditingController();
  final _cloneKey = TextEditingController();
  final _cloneVoice = TextEditingController();

  List<Map<String, String>> _voices = const [];
  String _status = '';

  @override
  void initState() {
    super.initState();
    final s = state.settings;
    _trUrl.text = s.trUrl;
    _trKey.text = s.trKey;
    _trModel.text = s.trModel;
    _asrUrl.text = s.asrUrl;
    _asrKey.text = s.asrKey;
    _cloneUrl.text = s.cloneUrl;
    _cloneKey.text = s.cloneKey;
    _cloneVoice.text = s.cloneVoice;
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final v = await TtsService.voices();
      if (!mounted) return;
      setState(() => _voices = v);
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [_trUrl, _trKey, _trModel, _asrUrl, _asrKey, _cloneUrl, _cloneKey, _cloneVoice]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontSize: 17, letterSpacing: 1)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _langCard(),
          _asrCard(),
          _translateCard(),
          _voiceCard(),
          _dataCard(),
        ],
      ),
    );
  }

  // ---------- 通用容器 ----------
  Widget _card(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 10),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(title, style: const TextStyle(fontSize: 12, letterSpacing: 1.4, color: kInk)),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, {String? hint, required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: kInkSoft)),
                if (hint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(hint, style: labelStyle(size: 10.5, spacing: 0.2)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }

  Widget _select(String value, List<MapEntry<String, String>> options, ValueChanged<String> onChanged) {
    return DropdownButton<String>(
      value: options.any((o) => o.key == value) ? value : (options.isEmpty ? null : options.first.key),
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(10),
      style: const TextStyle(fontSize: 13, color: kInk, fontWeight: FontWeight.w500),
      items: [
        for (final o in options)
          DropdownMenuItem(value: o.key, child: Text(o.value)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _field(String label, TextEditingController c, {String hint = '', bool secret = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle(size: 11, color: kInkSoft, spacing: 0.4)),
          const SizedBox(height: 4),
          TextField(
            controller: c,
            obscureText: secret,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: kMuted),
              filled: true,
              fillColor: kPaper.withOpacity(0.6),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kLineStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kAccent),
              ),
            ),
            onChanged: (_) => _persist(),
          ),
        ],
      ),
    );
  }

  void _persist() {
    final s = state.settings;
    s.trUrl = _trUrl.text.trim();
    s.trKey = _trKey.text.trim();
    s.trModel = _trModel.text.trim();
    s.asrUrl = _asrUrl.text.trim();
    s.asrKey = _asrKey.text.trim();
    s.cloneUrl = _cloneUrl.text.trim();
    s.cloneKey = _cloneKey.text.trim();
    s.cloneVoice = _cloneVoice.text.trim();
    state.saveSettings();
  }

  // ---------- 语言 ----------
  Widget _langCard() {
    final s = state.settings;
    return _card('语言', [
      _row('我说的语言', hint: '语音识别的输入语言',
          trailing: _select(
            s.asrLang,
            [for (final l in kLanguages) MapEntry(l.code, l.name)],
            (v) {
              setState(() => s.asrLang = v);
              state.saveSettings();
            },
          )),
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Text('要翻译成哪些语言', style: const TextStyle(fontSize: 13, color: kInkSoft)),
      ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final l in kLanguages)
            GestureDetector(
              onTap: () {
                setState(() {
                  if (s.targets.contains(l.code)) {
                    if (s.targets.length > 1) s.targets.remove(l.code);
                  } else {
                    s.targets.add(l.code);
                  }
                });
                state.saveSettings();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: s.targets.contains(l.code) ? kAccent : kCard.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: s.targets.contains(l.code) ? kAccent : kLineStrong),
                ),
                child: Text(
                  l.name,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: s.targets.contains(l.code) ? Colors.white : kInkSoft,
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 4),
      Text('可多选。选中几种，每条记录就同时生成几份译文。',
          style: labelStyle(size: 10.5, spacing: 0.2)),
      _row('录音后自动朗读', hint: '保存后按第一种目标语言朗读',
          trailing: Switch(
            value: s.autoSpeak,
            activeTrackColor: kAccent,
            onChanged: (v) {
              setState(() => s.autoSpeak = v);
              state.saveSettings();
            },
          )),
    ]);
  }

  // ---------- 转写 ----------
  Widget _asrCard() {
    final s = state.settings;
    return _card('语音转文字', [
      _row('转写方式', hint: '系统识别免费；自建接口在没 Google 服务的机器上更稳',
          trailing: _select(
            s.asrEngine,
            const [
              MapEntry('device', '设备内置识别'),
              MapEntry('cloud', '自建转写接口'),
            ],
            (v) {
              setState(() => s.asrEngine = v);
              state.saveSettings();
            },
          )),
      if (s.asrEngine == 'cloud') ...[
        _field('接口地址', _asrUrl, hint: 'https://你的服务/v1/audio/transcriptions'),
        _field('API Key', _asrKey, hint: 'Bearer Token', secret: true),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '按 OpenAI Whisper 兼容协议：POST multipart，字段 file + model + language，返回 {"text": "..."}。',
            style: labelStyle(size: 10.5, spacing: 0),
          ),
        ),
      ],
    ]);
  }

  // ---------- 翻译 ----------
  Widget _translateCard() {
    final s = state.settings;
    return _card('翻译服务', [
      _row('服务方式', hint: '自动会先试公共接口，失败再试自建',
          trailing: _select(
            s.trEngine,
            const [
              MapEntry('auto', '自动（免费公共接口）'),
              MapEntry('custom', '自建接口'),
            ],
            (v) {
              setState(() => s.trEngine = v);
              state.saveSettings();
            },
          )),
      if (s.trEngine == 'custom') ...[
        _field('接口地址', _trUrl, hint: 'https://api.openai.com/v1/chat/completions'),
        _field('API Key', _trKey, hint: 'sk-...', secret: true),
        _field('模型', _trModel, hint: 'gpt-4o-mini / glm-4-flash'),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('按 OpenAI 兼容的 /chat/completions 协议调用，密钥只存在本机。',
              style: labelStyle(size: 10.5, spacing: 0)),
        ),
      ],
    ]);
  }

  // ---------- 声音 ----------
  Widget _voiceCard() {
    final s = state.settings;
    final bases = s.targets.map((t) => langOf(t).ttsLocale.split('-').first.toLowerCase()).toSet();
    final filtered = _voices
        .where((v) => bases.any((b) => (v['locale'] ?? '').toLowerCase().startsWith(b)))
        .toList();
    final list = filtered.isEmpty ? _voices : filtered;

    return _card('声音', [
      _row('朗读方式', hint: '克隆音色需要你自己的服务',
          trailing: _select(
            s.ttsMode,
            const [
              MapEntry('system', '系统音色'),
              MapEntry('clone', '我的克隆音色'),
            ],
            (v) {
              setState(() => s.ttsMode = v);
              state.saveSettings();
            },
          )),
      if (s.ttsMode == 'system')
        _row('系统音色', hint: list.isEmpty ? '这台设备没列出可用音色' : '按目标语言自动匹配',
            trailing: _select(
              s.sysVoice,
              [
                const MapEntry('', '自动匹配'),
                for (final v in list) MapEntry(v['name'] ?? '', '${v['name']} · ${v['locale']}'),
              ],
              (v) {
                setState(() => s.sysVoice = v);
                state.saveSettings();
              },
            )),
      if (s.ttsMode == 'clone') ...[
        _field('声音克隆接口', _cloneUrl, hint: 'https://你的服务/tts'),
        _field('API Key', _cloneKey, hint: 'Bearer Token', secret: true),
        _field('音色 ID', _cloneVoice, hint: 'voice_id / speaker_id'),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'POST JSON：{ text, language, voice_id }，返回音频二进制，或返回含 audio_url / audio_base64 的 JSON。'
            '先用你自己的声音样本在该服务完成注册。',
            style: labelStyle(size: 10.5, spacing: 0),
          ),
        ),
      ],
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _testVoice,
              style: OutlinedButton.styleFrom(
                foregroundColor: kInkSoft,
                side: const BorderSide(color: kLineStrong),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                minimumSize: const Size(0, 40),
              ),
              child: const Text('试听一句', style: TextStyle(fontSize: 12.5)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _persist();
                setState(() => _status = '已保存到本机');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('设置已保存')));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: kInkSoft,
                side: const BorderSide(color: kLineStrong),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                minimumSize: const Size(0, 40),
              ),
              child: const Text('保存设置', style: TextStyle(fontSize: 12.5)),
            ),
          ),
        ],
      ),
      if (_status.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_status, style: const TextStyle(fontSize: 11, color: Color(0xFF3F6B4F))),
        ),
    ]);
  }

  Future<void> _testVoice() async {
    final s = state.settings;
    final to = s.targets.first;
    final sample = to == 'zh-CN' ? '这是我自己的声音，听起来还习惯吗。' : 'This is a quick test of my voice.';
    setState(() => _status = '正在朗读…');
    try {
      await TtsService.speak(sample, to, s);
      if (!mounted) return;
      setState(() => _status = s.ttsMode == 'clone' ? '已调用克隆接口，请听效果' : '用的是系统音色');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '朗读失败：$e');
    }
  }

  // ---------- 数据 ----------
  Widget _dataCard() {
    return _card('数据', [
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: kCard,
                    title: const Text('清空全部记录？', style: TextStyle(fontSize: 16)),
                    content: Text('${state.notes.length} 条记录会被删除，无法恢复。',
                        style: const TextStyle(fontSize: 13)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('清空')),
                    ],
                  ),
                );
                if (ok == true) {
                  await state.clearAll();
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('已清空')));
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: kAccent,
                side: const BorderSide(color: kLineStrong),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                minimumSize: const Size(0, 40),
              ),
              child: const Text('清空记录', style: TextStyle(fontSize: 12.5)),
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 9, bottom: 2),
        child: Text('记录、音频、密钥都只保存在这台设备上。',
            style: labelStyle(size: 10.5, spacing: 0)),
      ),
    ]);
  }
}
