# 快速开始指南

## 🚀 5 分钟上手

### 前提条件

确保已安装：
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- Android Studio / Android SDK

### 构建 APK

```bash
# 1. 进入项目
cd tv-live-app

# 2. 获取依赖
flutter pub get

# 3. 构建 Release APK
flutter build apk --release --split-per-abi
```

### 安装到 TV

```bash
# 通过 ADB 安装
adb connect <TV_IP>:5555
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

或通过 U 盘拷贝 APK 到 TV 安装。

## 📺 配置频道

### 方式 1: 修改本地配置

编辑 `assets/config/channels.json`，添加你的直播源：

```json
{
  "channels": [
    {
      "id": "my_channel",
      "name": "我的频道",
      "url": "http://your-stream-url.m3u8",
      "group": "自定义"
    }
  ]
}
```

重新构建 APK 即可生效。

### 方式 2: 远程配置 URL

1. 打开应用
2. 点击右上角设置图标
3. 选择"输入配置 URL"
4. 输入你的 JSON 配置地址

## 🎮 TV 遥控器

| 按键 | 功能 |
|------|------|
| ⬆️ 上 | 上一个频道 |
| ⬇️ 下 | 下一个频道 |
| ✅ 确认 | 播放/暂停 |
| ⬅️ 返回 | 返回/退出全屏 |

## 📊 预期体积

| APK 类型 | 大小 |
|---------|------|
| armeabi-v7a | ~5-6 MB |
| arm64-v8a | ~6-7 MB |

## ⚠️ 常见问题

**Q: 视频无法播放？**
- 检查直播源 URL 是否有效
- 确保 TV 已连接网络
- 尝试其他直播源测试

**Q: 遥控器无法操作？**
- 确保焦点在频道列表上
- 播放时按方向键切换频道

**Q: 体积超过 10MB？**
- 确保使用 `--split-per-abi` 构建
- 检查是否有多余的图片资源

---

需要帮助？查看 [README.md](README.md) 获取完整文档。
