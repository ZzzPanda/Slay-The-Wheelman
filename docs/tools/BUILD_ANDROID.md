# Slay-The-Robot Android 构建指南

## 概述
本文档提供在 macOS 环境下构建 Slay-The-Robot Android APK 的完整指南。

## 目录结构
- `export_presets.cfg` - Godot 导出配置
- `scripts/build_android.sh` - 构建脚本

## 环境要求

### 1. Android SDK
Android SDK 已安装在: `~/android-sdk/`

关键组件:
- platform-tools
- platforms;android-34
- build-tools;34.0.0

### 2. Java
```bash
java -version
# 应显示 OpenJDK 17+
```

### 3. Godot
当前使用 Godot 4.6.1.stable

## 构建方法

### 方法一：使用构建脚本
```bash
cd ~/openclaw/workspace/Slay-The-Robot
./scripts/build_android.sh
```

### 方法二：手动构建
```bash
cd ~/openclaw/workspace/Slay-The-Robot
export ANDROID_HOME=~/android-sdk
export ANDROID_SDK_ROOT=~/android-sdk

# Debug 构建
godot --headless --export-debug "Android Debug" builds/android_debug.apk

# Release 构建
godot --headless --export-release "Android Release" builds/android_release.apk
```

## 已知问题

### 问题：导出失败 "configuration errors"

**症状:**
```
ERROR: Cannot export project with preset "Android Debug" due to configuration errors:
```

**可能原因和解决方案:**

1. **项目名称包含空格**
   - 编辑 `project.godot` 中的 `config/name`
   - 使用无空格名称，如 `SlayTheRobot`

2. **.NET 配置问题**
   - 如果项目不使用 C#，可移除 `[dotnet]` 部分
   - 或安装 godot-mono 版本

3. **config_version 不匹配**
   - 确保使用与 Godot 版本匹配的配置
   - Godot 4.6+ 应使用 `config_version=5`

4. **导出模板**
   - 确认导出模板已正确安装
   - 位置: `~/.local/share/godot/export_templates/`

### 问题：找不到 build tools

**症状:**
```
Could not find version of build tools that matches Target SDK, using 33.0.1
```

**解决方案:**
```bash
# 安装正确的 build-tools 版本
export ANDROID_HOME=~/android-sdk
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "build-tools;34.0.0"
```

## 手动 APK 构建（备选方案）

如果 Godot 导出持续失败，可以使用以下备选方案：

### 使用 Android Studio
1. 打开 Android Studio
2. 选择 "Import Project"
3. 选择 `~/openclaw/workspace/Slay-The-Robot`
4. 等待 Gradle 同步完成
5. Build → Build APK

### 使用 Gradle 命令行
```bash
# 在项目目录中
./gradlew assembleDebug
```

## 配置详情

### export_presets.cfg 关键配置
```ini
android/min_sdk=24      # 最小支持版本 (Android 7.0)
android/target_sdk=34   # 目标版本 (Android 14)
android/package/unique_name="com.slaytherobot.game"
```

### APK 输出位置
- Debug: `builds/android_debug.apk`
- Release: `builds/android_release.apk`

## 故障排除

### 检查 Android SDK 状态
```bash
export ANDROID_HOME=~/android-sdk
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --list_installed
```

### 检查 Godot 导出模板
```bash
ls ~/.local/share/godot/export_templates/4.6.1.stable/
```

### 重新安装导出模板
```bash
godot --headless --editor
# 在编辑器中: Editor > Manage Export Templates
```

## 更多信息
- Godot Android 导出: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- Android SDK: https://developer.android.com/studio
