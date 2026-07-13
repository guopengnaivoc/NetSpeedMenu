<p align="center">
  <img src="images/app-icon.png" width="156" alt="NetSpeedMenu icon">
</p>

# NetSpeedMenu 1.2 User Guide

[简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Français](README.fr.md) · [Home](../README.md)

## Overview

NetSpeedMenu is a small macOS menu-bar utility. `↑` shows the current upload speed and `↓` shows the current download speed. Its menu-bar area is fixed at 57 points, and the app does not occupy the Dock.

The settings window provides:

- a “Launch silently at login” switch;
- the current login-item status;
- app description, version, and author information;
- a “退出网速” (Quit NetSpeedMenu) button.

It supports macOS 13 or later on both Intel and Apple Silicon Macs.

<p align="center">
  <img src="images/settings-window.jpg" width="460" alt="NetSpeedMenu settings window">
</p>

## Download and verify

Download `NetSpeedMenu-1.2-universal.dmg` from this repository’s [Releases](../../../releases/latest) page. The DMG is the recommended installation method.

Verify the download in Terminal:

```bash
shasum -a 256 ~/Downloads/NetSpeedMenu-1.2-universal.dmg
```

Expected SHA-256:

```text
92d47b7f0587d4daa878a29cfe73cb1a4271dda9fdb80796021604e430b7845e
```

## Install

1. Double-click `NetSpeedMenu-1.2-universal.dmg`.
2. Drag `网速.app` to the adjacent Applications folder.
3. Open the Applications folder and locate `网速`.
4. Follow the first-launch instructions below.

You can also use the PKG. Control-click `NetSpeedMenu-1.2-universal.pkg`, choose **Open**, and follow Installer. An administrator password may be required.

## Why macOS shows a warning

The app itself uses an ad-hoc signature created on the developer’s Mac, while the PKG installer itself is unsigned. **Neither uses an Apple Developer ID signature, and this release is not notarized by Apple.** Gatekeeper therefore cannot verify the developer identity or confirm that Apple checked this build. You may see:

- “The developer cannot be verified”;
- “Apple cannot check it for malicious software”;
- a dialog offering to move the app to the Trash.

These messages do not by themselves prove that malware was found, but they must not be ignored. Verify the source and SHA-256 before overriding anything.

## First launch: recommended method

1. Double-click `网速.app` once so macOS records the blocked launch.
2. If the dialog offers **Move to Trash**, choose **Done** or close the dialog. Do not choose Move to Trash.
3. Open **System Settings → Privacy & Security**.
4. Scroll to Security, find the blocked `网速` app, and click **Open Anyway**.
5. Confirm **Open** and enter your login password if requested.

Apple notes that Open Anyway is normally available for about one hour after the blocked launch. Once approved, the app is saved as an exception. See [Apple’s official instructions](https://support.apple.com/guide/mac-help/mh40617/mac).

You can also Control-click the app and choose **Open**. If that remains blocked, use Privacy & Security as described above.

## Stop when the warning is more serious

If macOS explicitly says the app “will damage your computer,” contains malware, is damaged, or has been modified:

- do not remove quarantine attributes in Terminal;
- do not disable Gatekeeper globally;
- delete the file and download it again from the official Releases page;
- verify SHA-256 again;
- if it still differs, do not run it; build from source instead.

Apple explains the meanings of these warnings in [Safely open apps on your Mac](https://support.apple.com/102445).

## Use

- `↑`: current upload speed
- `↓`: current download speed
- Open from Finder or Applications: show settings
- Launch at login: run silently in the menu bar
- Close the settings window: keep the app running
- Click 退出网速 (Quit NetSpeedMenu): fully terminate the app

## Privacy

The app only reads cumulative network-interface byte counters exposed by macOS. It does not upload files, send telemetry, include ads, or retain network content.

## Uninstall

1. Open settings and turn off Launch silently at login.
2. Click 退出网速 (Quit NetSpeedMenu).
3. Move `/Applications/网速.app` to the Trash.

Version: 1.2

Author: Guo Peng (郭鹏)
