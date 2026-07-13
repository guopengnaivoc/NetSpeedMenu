<p align="center">
  <img src="docs/images/app-icon.png" width="156" alt="NetSpeedMenu icon">
</p>

# NetSpeedMenu / 网速

一个轻量级 macOS 菜单栏实时网速显示器。上方显示上传速度，下方显示下载速度；支持 Intel 与 Apple Silicon。

<p align="center">
  <img src="docs/images/settings-window.jpg" width="460" alt="网速设置窗口">
</p>

[简体中文](docs/README.zh-CN.md) · [English](docs/README.en.md) · [日本語](docs/README.ja.md) · [Français](docs/README.fr.md)

## 功能

- 菜单栏固定 57 点宽，上下两行显示上传与下载速度
- 支持 Intel `x86_64` 与 Apple Silicon `arm64`
- 支持开机后静默启动
- 设置窗口包含启动项开关、软件说明、版本、作者和退出按钮
- 不收集数据、不包含分析服务、不向外发送网络数据

## 下载

请从本仓库的 [Releases](../../releases/latest) 页面下载：

- `NetSpeedMenu-1.2-universal.dmg`（推荐）
- `NetSpeedMenu-1.2-universal.pkg`

## 重要安全说明

App 本体使用开发电脑上的 ad-hoc（临时）签名；PKG 安装器本身未签名。**两者都没有 Apple Developer ID 签名，也没有经过 Apple 公证**。因此 macOS 可能显示“无法验证开发者”或“Apple 无法检查是否包含恶意软件”。这不等同于系统已经判定它是恶意软件，但表示 Apple 没有验证此构建。

只有在以下条件全部满足时才应选择“仍要打开”：

1. 安装包来自本仓库的官方 Releases 页面；
2. SHA-256 与发布说明一致；
3. 你理解并接受未公证软件的风险。

如果系统明确提示“会损坏你的电脑”“包含恶意软件”或文件已经损坏，**不要绕过警告**。请删除文件、重新下载并核对哈希。Apple 的官方说明：[安全地打开 Mac App](https://support.apple.com/102445)。

完整安装和首次打开步骤请阅读[中文说明书](docs/README.zh-CN.md)。

## 当前版本校验值

```text
92d47b7f0587d4daa878a29cfe73cb1a4271dda9fdb80796021604e430b7845e  NetSpeedMenu-1.2-universal.dmg
3fd7e8e5e5af1ecf3004e72591518ff896c6c2ed4735d0171f722f50e1a15a61  NetSpeedMenu-1.2-universal.pkg
```

## 从源码构建

需要 macOS 13 或更高版本及 Xcode Command Line Tools。

```bash
chmod +x build-app.sh build-dmg.sh build-installer.sh
./build-dmg.sh
```

作者：郭鹏
