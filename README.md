# 声笺 · 说出来，存下来

随手说话，自动变成文字；按你选的语言翻译成多份译文；再用**你自己的音色**朗读出来。

一个项目，两种形态：

| 目录 | 形态 | 说明 |
| --- | --- | --- |
| `web/` | 网页版（单文件 PWA） | 手机浏览器直接打开就能用，可添加到主屏幕，无需编译。源码为单个 `声笺.html`，见 [web/README.md](web/README.md) |
| `app/` | 原生版（Flutter） | 完整工程源码，自己打包成 APK / IPA，能用系统级麦克风和识别 |

两个版本共用同一套数据模型和同一套服务接口约定，可以先用网页版验证，再切原生版。

---

## 一、网页版怎么用

网页版是一个自包含的单文件，CSS / JS 全内联，没有任何构建步骤。

**必须通过 https 或 localhost 访问**：浏览器的麦克风权限只在安全上下文里开放，直接双击
打开 `file://` 会拿不到麦克风。最省事的两种方式：

1. 已发布的链接：直接打开，添加到主屏幕（iOS「分享 → 添加到主屏幕」/ Android「菜单 → 添加到主屏幕」）。
2. 自己部署：把 `声笺.html` 传到任意支持 https 的静态托管（对象存储、Vercel、GitHub Pages 等）。

单文件的具体实现与限制见 [web/README.md](web/README.md)。

---

## 二、原生版（Flutter）怎么跑

```bash
cd app
flutter create .            # 生成 android/ ios/ 等平台壳（会保留已有的 lib/）
# 用 platform/ 里的文件替换生成物：
#   platform/AndroidManifest.xml  ->  android/app/src/main/AndroidManifest.xml
#   platform/ios-Info.plist-keys.md 里的键 ->  ios/Runner/Info.plist
flutter pub get
flutter run                 # 或 flutter build apk --release
```

`lib/` 是完整实现，不是占位代码：

```
lib/
  main.dart                     入口、主题
  models.dart                   19 种语言表、Note、Settings
  app_state.dart                记录与设置的本地持久化
  theme.dart                    纸墨配色
  pages/home_page.dart          记录列表、统计、卡片操作
  pages/record_page.dart        录音 + 实时转写 + 波形 + 保存
  pages/settings_page.dart      语言 / 转写 / 翻译 / 声音设置
  services/asr_service.dart     设备识别 + 自建 Whisper 接口
  services/translate_service.dart  公共接口自动降级 + OpenAI 兼容接口
  services/tts_service.dart     系统音色 + 克隆音色
  services/pipeline.dart        逐条补翻译、边翻边存
```

依赖：`record`、`speech_to_text`、`flutter_tts`、`audioplayers`、
`shared_preferences`、`path_provider`、`http`、`permission_handler`。

**说明**：这个仓库里的 Flutter 部分是按标准 API 写的，但没有在装有 Flutter SDK 的机器上
编译过。第一次 `flutter run` 如果报某个插件的 API 变动，按报错改一处即可（版本都在
`pubspec.yaml` 里锁了大版本）。

---

## 三、三个 AI 接口约定（接你自己的服务时看这里）

网页版和原生版用的是同一套契约，填进设置就能跑。

### 1. 转写接口（可选）

`POST {asrUrl}`，`multipart/form-data`，字段：

```
file      录音文件
model     whisper-1
language  zh / en / ja ...
Header    Authorization: Bearer {asrKey}
```

返回：`{"text": "识别出的文字"}`

### 2. 翻译接口（可选）

OpenAI 兼容的 `POST {trUrl}/chat/completions`：

```json
{
  "model": "gpt-4o-mini",
  "temperature": 0.2,
  "messages": [
    {"role": "system", "content": "只输出译文..."},
    {"role": "user", "content": "要翻译的文本"}
  ]
}
```

返回惯例的 `choices[0].message.content`。国内可用智谱、月之暗面、DeepSeek 的兼容地址。

### 3. 声音克隆接口（可选）

`POST {cloneUrl}`：

```json
{ "text": "要读的内容", "language": "en", "voice_id": "你的音色 ID" }
```

返回二选一：

- 直接返回音频二进制（`Content-Type: audio/mpeg|wav|m4a`）
- 返回 JSON，含 `audio_url` 或 `audio_base64`

音色本身要在该服务上用你自己的声音样本先注册（一般 10–30 秒清晰人声）。
火山引擎声音复刻、MiniMax、Fish Audio、ElevenLabs 都能按这个形状对接，
各家字段名不同的话，改 `tts_service.dart` / 网页版的 `speakClone()` 一处即可。

---

## 四、已知限制（如实说明）

- 网页版的实时转写依赖浏览器，不是自己实现的 ASR。
- 免费公共翻译接口有额度，长文本会被截断（MyMemory 单次 480 字符）。
- 声音克隆需要外部服务，仓库里不包含任何模型权重，也不包含密钥。
- 原生版未在 CI 里构建过；平台权限文件要按第二节手动替换。
- iOS 上「边录边识别」会争抢音频会话，建议切到自建转写接口。

---

## 五、许可

个人自用。第三方接口的账号、额度和合规责任由使用者自行承担。
