# iOS 需要补进 Info.plist 的键

`flutter create .` 生成 `ios/Runner/Info.plist` 后，在顶层 `<dict>` 里加入下面四条。
不加的话，录音和系统语音识别都会被系统直接拒绝，且没有任何提示。

```xml
<key>NSMicrophoneUsageDescription</key>
<string>声笺需要麦克风来录制你想说的话，并转成文字。</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>声笺需要语音识别权限，把你说的话实时转成文字。</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 说明

- `NSMicrophoneUsageDescription`：录音和声音克隆样本都用到。
- `NSSpeechRecognitionUsageDescription`：设备内置识别（speech_to_text）。
- `UIBackgroundModes` / `audio`：让录音在切后台时不立刻断（可选，不想要可以删掉）。
- `NSAllowsArbitraryLoads`：允许访问 http 的自建接口；只用 https 的话可以删掉。

## 已知的平台差异

iOS 上「边录音边做系统语音识别」会争抢同一个音频会话，部分机型会出现识别没结果。
遇到这种情况，在设置 → 语音转文字里切成「自建转写接口」：App 只录音，停下来后把文件传给
Whisper 兼容接口转写，结果更稳。
