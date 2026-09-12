# YZBJFPV APP 远程更新指南

> 版本规则：统一 `V0.0.1.1Beta`，较大改动 +0.0.0.1（如 V0.0.1.2Beta）

## 一、更新系统架构

```
admin后台「系统设置→APP版本管理」
    ↓ 保存到 data/settings.json 的 app 字段
服务端 GET /api/yzbjfpv-app-version（公开）
    ↓ 返回 {version, force, deadline, changelog, downloads, serverTime}
APP启动 → Api.checkUpdate() → 与本地 AppConfig.appVersion 对比
    ├─ 服务器版本更新 且 force=true        → 阻塞弹窗（不可关闭，必须更新）
    ├─ 服务器版本更新 且 force=false       → 可关闭弹窗（稍后更新）
    │    └─ 过了 deadline 最晚日期        → 自动视为强制
    └─ 版本相同/更旧                       → 无感
```

## 二、后台发版步骤（admin页面）

1. 管理员登录 `https://air.yzbjfpv.top/admin`（91ID账号，超管8888）
2. 左侧「系统设置」→「APP 版本管理」
3. 填写：
   - **最新版本号**：如 `V0.0.1.2Beta`
   - **更新策略**：`用户选择更新` 或 `强制更新`
   - **最晚日期**：选择更新的过期日（过期自动转强制）
   - **更新日志**：用户可见的更新说明
   - **三端下载地址**：Android APK / Windows 安装包 / iOS 指引链接
4. 点「发布版本配置」→ 全部APP下次启动弹更新提示

## 三、各端编译命令（Windows 开发机）

```powershell
$env:Path="D:\flutter-sdk\flutter\bin;$env:Path"
Set-Location d:\yzbjfpv-app

# Android APK（产物 build\app\outputs\flutter-apk\app-release.apk）
flutter build apk --release

# Windows EXE（产物 build\windows\x64\runner\Release\yzbjfpv.exe）
flutter build windows --release

# iOS：需Mac打包；Windows本机只能生成/维护工程（ios/目录）
```

编译前记得更新 `lib/core/config.dart` 的 `appVersion` 常量（与后台发布的版本号一致）。

## 四、本地APP版本号位置

- `lib/core/config.dart` → `static const String appVersion = 'V0.0.1.1Beta';`
- 修改后必须重新编译打包分发

## 五、Windows 安装包（IExpress 失败时的备选）

1. **便携版（推荐）**：`dist\pkg\payload.zip` 解压即用（内含完整Release）
2. PowerShell 自解压脚本方案（install.cmd 已在 dist\pkg\）
3. 7-Zip SFX / Inno Setup（备选）

## 六、服务器地址配置

- 默认：Android模拟器 `10.0.2.2:4000`，其他 `localhost:4000`
- 生产：`https://air.yzbjfpv.top`（config.dart 的 prodUrl，我的页可覆盖，SharedPreferences 持久化）
