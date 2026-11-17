# Flutter 目录说明

## 首次运行

```bash
cd app
flutter create .      # 生成 android/ ios/ web/ 等平台壳
```

`flutter create .` 会重新生成平台目录，用本仓库 `platform/` 里的内容覆盖回去：

1. `platform/AndroidManifest.xml` → `android/app/src/main/AndroidManifest.xml`
2. `platform/ios-Info.plist-keys.md` 里的四个键 → `ios/Runner/Info.plist`

然后：

```bash
flutter pub get
flutter run
```

## 打包

```bash
flutter build apk --release       # Android
flutter build ios --release       # iOS（需要 macOS + Xcode）
```

## 主要文件

| 文件 | 作用 |
| --- | --- |
| `lib/main.dart` | 入口，初始化状态、启动后台补翻 |
| `lib/models.dart` | 19 种语言、Note、Settings、序列化 |
| `lib/app_state.dart` | 单例状态 + SharedPreferences 持久化 |
| `lib/pages/home_page.dart` | 列表、统计、卡片操作 |
| `lib/pages/record_page.dart` | 录音、实时转写、波形、保存 |
| `lib/pages/settings_page.dart` | 语言、转写、翻译、声音、数据 |
| `lib/services/asr_service.dart` | 设备识别 / 自建 Whisper |
| `lib/services/translate_service.dart` | 公共接口降级 / 自建 OpenAI 兼容 |
| `lib/services/tts_service.dart` | 系统音色 / 克隆音色 |
| `lib/services/pipeline.dart` | 逐目标语言翻译并落盘 |

## 注意

- 录音文件存在 `应用文档目录/recordings/`，以 `.m4a` 保存。
- 状态里只存文字与音频路径，音频本体在文件系统，不塞进 SharedPreferences。
- 所有 AI 接口地址和 Key 都只写在本机 SharedPreferences，不上传。
