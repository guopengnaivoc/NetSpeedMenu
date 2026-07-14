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
- 首次成功打开后，默认注册为登录项；以后重新登录或重启后静默启动
- 设置窗口显示系统真实的登录项状态，并可直接打开登录项设置或重试启用
- 支持按住 Command 拖动到用户希望的菜单栏位置
- 不收集数据、不包含分析服务、不向外发送网络数据

## 下载

请从本仓库的 [Releases](../../releases/latest) 页面下载：

- `NetSpeedMenu-1.3-universal.dmg`（推荐）
- `NetSpeedMenu-1.3-universal.pkg`

## 图解安装与首次打开

按下图的蓝色箭头安装。如果只看到“无法验证开发者”或“Apple 无法检查…”这类普通未签名警告，按绿色路线操作；如果明确提示恶意软件、会损坏电脑、文件已损坏或被修改，立即停止。

<p align="center">
  <img src="docs/images/install-guide.zh-CN.svg" width="900" alt="图解：普通未签名或未公证警告中不要点击移到废纸篓，并到隐私与安全性选择仍要打开；如果提示恶意软件、会损坏电脑、文件已损坏或被修改则停止">
</p>

## 登录后自动启动

<p align="center">
  <img src="docs/images/autostart-guide.zh-CN.svg" width="900" alt="图解：将网速安装到应用程序并至少成功打开一次；确认登录项已启用或按提示批准；以后登录时自动启动并通常显示在菜单栏右侧状态区域；按住 Command 键拖移可调整位置">
</p>

安装到“应用程序”后，必须至少成功打开一次，App 才能为当前用户注册登录项。默认启用后，每次登录时（包括重启后的登录）都会静默启动，并通常显示在菜单栏右侧状态区域；如果设置窗口提示“还差一步”，请点击“打开登录项设置”并允许“网速”。菜单栏空间不足时，macOS 可能暂时隐藏状态项。App 不能强制始终固定在最右侧；你可以按住 Command 键并拖移网速显示。每台新 Mac 和同一台 Mac 上的每个用户账户都需要分别完成一次首次打开与批准。

## 重要安全说明

App 本体使用开发电脑上的 ad-hoc（临时）签名；PKG 安装器本身未签名。**两者都没有 Apple Developer ID 签名，也没有经过 Apple 公证**。因此 macOS 可能显示“无法验证开发者”或“Apple 无法检查是否包含恶意软件”。这不等同于系统已经判定它是恶意软件，但表示 Apple 没有验证此构建。

只有在以下条件全部满足时才应选择“仍要打开”：

1. 安装包来自本仓库的官方 Releases 页面；
2. SHA-256 与发布说明一致；
3. 你理解并接受未公证软件的风险。

如果系统明确提示“会损坏你的电脑”“包含恶意软件”或文件已经损坏，**不要绕过警告**。请删除文件、重新下载并核对哈希。Apple 的官方说明：[安全地打开 Mac App](https://support.apple.com/102445)。

完整文字步骤和故障处理请阅读[中文说明书](docs/README.zh-CN.md)。

## 当前版本校验值

```text
cbae75d931538aef45ee8ea4a2efdabdb9adc50d99f2bff95795eed9a01c7a47  NetSpeedMenu-1.3-universal.dmg
e779cffd8a5df4fde1d62ec2c806590956d5d2f50deb8c6fb45729b6426c6eaf  NetSpeedMenu-1.3-universal.pkg
```

## 从源码构建

需要 macOS 13 或更高版本及 Xcode Command Line Tools。

```bash
chmod +x build-app.sh build-dmg.sh build-installer.sh
./build-dmg.sh
```

作者：郭鹏
