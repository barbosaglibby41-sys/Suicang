# Suicang

现代化、跨平台的 AI 角色聊天与创作工作台。

## 目标平台

- iOS
- Android
- Windows

## 技术方向

Flutter + Riverpod + GoRouter + Drift + Dio

## 当前状态

iOS 优先开发，当前版本为 `1.01`。包含应用入口、主题系统、路由、移动端底部导航、发现页、聊天页和 OpenAI Compatible Provider 架构。

每次功能更新递增版本号：`1.02`、`1.03`、`1.04`。

GitHub Actions 会在手动触发或推送 `v*` 标签时构建未签名 IPA，并上传到 Actions Artifacts。IPA 不包含 Apple 签名，需使用者自行签名安装。

## 本地运行

需要安装 Flutter SDK 后执行：

```bash
flutter pub get
flutter run
```
