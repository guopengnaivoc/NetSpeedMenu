#import <AppKit/AppKit.h>
#import <CoreServices/CoreServices.h>
#import <ServiceManagement/ServiceManagement.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <net/if_dl.h>

typedef struct {
    uint64_t uploaded;
    uint64_t downloaded;
} NetworkTotals;

static NSString * const AutoLaunchPreferenceKey = @"AutoLaunchEnabled";
static NSString * const StatusItemAutosaveName = @"local.codex.NetSpeedMenu.primary";
// Keep the status item tightly fitted around the widest two-digit/two-decimal
// label (for example ↑99.99M/S) while preserving anti-clipping allowance.
static const CGFloat StatusItemWidth = 44.0;
static const CGFloat SpeedFontSize = 7.25;

static BOOL IsLoginItemOpenEvent(NSAppleEventDescriptor *event) {
    return [event paramDescriptorForKeyword:keyAELaunchedAsLogInItem] != nil;
}

static NetworkTotals ReadNetworkTotals(void) {
    struct ifaddrs *interfaces = NULL;
    NetworkTotals totals = {0, 0};
    if (getifaddrs(&interfaces) != 0) return totals;

    for (struct ifaddrs *item = interfaces; item != NULL; item = item->ifa_next) {
        if (!item->ifa_addr || !item->ifa_data) continue;
        if (item->ifa_addr->sa_family != AF_LINK) continue;
        if (!(item->ifa_flags & IFF_UP) || (item->ifa_flags & IFF_LOOPBACK)) continue;

        const struct if_data *data = (const struct if_data *)item->ifa_data;
        totals.uploaded += data->ifi_obytes;
        totals.downloaded += data->ifi_ibytes;
    }

    freeifaddrs(interfaces);
    return totals;
}

@interface SpeedView : NSView
- (void)updateUpload:(double)upload download:(double)download;
@end

@implementation SpeedView {
    NSTextField *_uploadLabel;
    NSTextField *_downloadLabel;
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _uploadLabel = [NSTextField labelWithString:@"↑0B/S"];
        _downloadLabel = [NSTextField labelWithString:@"↓0B/S"];
        for (NSTextField *label in @[_uploadLabel, _downloadLabel]) {
            label.font = [NSFont monospacedDigitSystemFontOfSize:SpeedFontSize weight:NSFontWeightMedium];
            label.textColor = NSColor.labelColor;
            label.alignment = NSTextAlignmentRight;
            label.lineBreakMode = NSLineBreakByClipping;
            [self addSubview:label];
        }
    }
    return self;
}

- (void)layout {
    [super layout];
    CGFloat rowHeight = self.bounds.size.height / 2.0;
    _uploadLabel.frame = NSMakeRect(0, rowHeight - 1, self.bounds.size.width, rowHeight + 1);
    _downloadLabel.frame = NSMakeRect(0, 0, self.bounds.size.width, rowHeight + 1);
}

- (NSView *)hitTest:(NSPoint)point {
    // Let the status-bar button receive Command-drag events so users can
    // position the item where they prefer. The button has no normal action.
    return nil;
}

+ (NSString *)formatSpeed:(double)value {
    NSArray<NSString *> *units = @[@"B/S", @"K/S", @"M/S", @"G/S"];
    value = MAX(0, value);
    NSUInteger index = 0;
    while (value >= 999.5 && index < units.count - 1) {
        value /= 1000;
        index++;
    }
    if (index == 0) return [NSString stringWithFormat:@"%.0f%@", value, units[index]];
    if (value >= 99.995) return [NSString stringWithFormat:@"%.0f%@", value, units[index]];
    return [NSString stringWithFormat:@"%.2f%@", value, units[index]];
}

- (void)updateUpload:(double)upload download:(double)download {
    _uploadLabel.stringValue = [NSString stringWithFormat:@"↑%@", [SpeedView formatSpeed:upload]];
    _downloadLabel.stringValue = [NSString stringWithFormat:@"↓%@", [SpeedView formatSpeed:download]];
}
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate {
    NSStatusItem *_statusItem;
    SpeedView *_speedView;
    NSTimer *_timer;
    NetworkTotals _previous;
    NSDate *_previousDate;
    NSWindow *_settingsWindow;
    NSButton *_autoLaunchButton;
    NSTextField *_autoLaunchStatusLabel;
    NSButton *_loginItemActionButton;
    NSError *_lastAutoLaunchError;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    // The login-item marker belongs to the first kAEOpenApplication event.
    // AppKit has not delivered that event yet in applicationDidFinishLaunching,
    // so install the handler before launch finishes and decide there.
    [NSAppleEventManager.sharedAppleEventManager
        setEventHandler:self
             andSelector:@selector(handleOpenApplicationEvent:withReplyEvent:)
           forEventClass:kCoreEventClass
              andEventID:kAEOpenApplication];
}

- (void)handleOpenApplicationEvent:(NSAppleEventDescriptor *)event
                     withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    if (IsLoginItemOpenEvent(event)) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self showSettingsWindow];
    });
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    _statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:StatusItemWidth];
    _statusItem.autosaveName = StatusItemAutosaveName;
    _speedView = [[SpeedView alloc] initWithFrame:NSMakeRect(0, 0, StatusItemWidth, NSStatusBar.systemStatusBar.thickness)];
    _speedView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [_statusItem.button addSubview:_speedView];
    _statusItem.button.enabled = YES;
    [_speedView updateUpload:0 download:0];

    _previous = ReadNetworkTotals();
    _previousDate = NSDate.date;

    [self applyStoredAutoLaunchPreference];
    _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)refresh:(NSTimer *)timer {
    NSDate *now = NSDate.date;
    NetworkTotals current = ReadNetworkTotals();
    NSTimeInterval elapsed = MAX([now timeIntervalSinceDate:_previousDate], 0.001);
    double upload = current.uploaded >= _previous.uploaded ? (current.uploaded - _previous.uploaded) / elapsed : 0;
    double download = current.downloaded >= _previous.downloaded ? (current.downloaded - _previous.downloaded) / elapsed : 0;
    [_speedView updateUpload:upload download:download];
    _previous = current;
    _previousDate = now;
}

- (BOOL)setLoginItemEnabled:(BOOL)enabled error:(NSError **)error {
    if (@available(macOS 13.0, *)) {
        SMAppService *service = SMAppService.mainAppService;
        if (enabled) {
            if (service.status == SMAppServiceStatusEnabled ||
                service.status == SMAppServiceStatusRequiresApproval) return YES;
            return [service registerAndReturnError:error];
        }
        if (service.status == SMAppServiceStatusNotRegistered) return YES;
        return [service unregisterAndReturnError:error];
    }
    return NO;
}

- (void)applyStoredAutoLaunchPreference {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    id storedValue = [defaults objectForKey:AutoLaunchPreferenceKey];
    if (storedValue) {
        // After first launch, System Settings is the source of truth. Do not
        // silently undo a choice the user made outside this app.
        return;
    }

    [defaults setBool:YES forKey:AutoLaunchPreferenceKey];

    NSError *error = nil;
    BOOL success = [self setLoginItemEnabled:YES error:&error];
    _lastAutoLaunchError = success ? nil : error;
}

- (void)autoLaunchChanged:(NSButton *)sender {
    BOOL awaitingApproval = NO;
    if (@available(macOS 13.0, *)) {
        awaitingApproval = SMAppService.mainAppService.status == SMAppServiceStatusRequiresApproval;
    }
    // Clicking the mixed “waiting for approval” state means cancel.
    // Approval itself is handled by the adjacent System Settings button.
    BOOL shouldEnable = awaitingApproval ? NO : sender.state == NSControlStateValueOn;
    NSError *error = nil;
    BOOL success = [self setLoginItemEnabled:shouldEnable error:&error];

    if (success) {
        [NSUserDefaults.standardUserDefaults setBool:shouldEnable forKey:AutoLaunchPreferenceKey];
        _lastAutoLaunchError = nil;
    } else {
        _lastAutoLaunchError = error;
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"无法修改登录启动设置";
        alert.informativeText = error.localizedDescription ?: @"请稍后重试。";
        [alert beginSheetModalForWindow:_settingsWindow completionHandler:nil];
    }
    [self updateAutoLaunchStatus];
}

- (void)updateAutoLaunchStatus {
    if (!_autoLaunchButton || !_autoLaunchStatusLabel) return;

    BOOL desired = [NSUserDefaults.standardUserDefaults boolForKey:AutoLaunchPreferenceKey];
    _autoLaunchButton.allowsMixedState = NO;
    _loginItemActionButton.hidden = YES;
    _loginItemActionButton.title = @"打开登录项设置";
    _autoLaunchStatusLabel.toolTip = nil;

    if (@available(macOS 13.0, *)) {
        switch (SMAppService.mainAppService.status) {
            case SMAppServiceStatusEnabled:
                _lastAutoLaunchError = nil;
                _autoLaunchButton.state = NSControlStateValueOn;
                _autoLaunchStatusLabel.stringValue = @"已启用：重新登录或重启后会静默运行";
                _autoLaunchStatusLabel.textColor = NSColor.secondaryLabelColor;
                break;
            case SMAppServiceStatusRequiresApproval:
                _lastAutoLaunchError = nil;
                _autoLaunchButton.allowsMixedState = YES;
                _autoLaunchButton.state = NSControlStateValueMixed;
                _autoLaunchStatusLabel.stringValue = @"还差一步：请在系统登录项中允许网速";
                _autoLaunchStatusLabel.textColor = NSColor.systemOrangeColor;
                _loginItemActionButton.hidden = NO;
                break;
            case SMAppServiceStatusNotRegistered:
                _autoLaunchButton.state = NSControlStateValueOff;
                if (desired && _lastAutoLaunchError) {
                    _autoLaunchStatusLabel.stringValue = @"尚未启用：请重试注册登录项";
                    _autoLaunchStatusLabel.textColor = NSColor.systemRedColor;
                    _loginItemActionButton.title = @"重试启用";
                    _loginItemActionButton.hidden = NO;
                    _autoLaunchStatusLabel.toolTip = _lastAutoLaunchError.localizedDescription;
                } else {
                    _autoLaunchStatusLabel.stringValue = @"已关闭：登录系统时不会自动启动";
                    _autoLaunchStatusLabel.textColor = NSColor.secondaryLabelColor;
                }
                break;
            case SMAppServiceStatusNotFound:
                _autoLaunchButton.allowsMixedState = YES;
                _autoLaunchButton.state = NSControlStateValueMixed;
                _autoLaunchStatusLabel.stringValue = @"暂时无法读取登录项状态";
                _autoLaunchStatusLabel.textColor = NSColor.systemRedColor;
                if (desired) {
                    _loginItemActionButton.title = @"重试启用";
                    _loginItemActionButton.hidden = NO;
                }
                _autoLaunchStatusLabel.toolTip = _lastAutoLaunchError.localizedDescription;
                break;
        }
    }
}

- (void)loginItemActionClicked:(NSButton *)sender {
    if (@available(macOS 13.0, *)) {
        if (SMAppService.mainAppService.status == SMAppServiceStatusRequiresApproval) {
            [SMAppService openSystemSettingsLoginItems];
            return;
        }

        NSError *error = nil;
        BOOL success = [self setLoginItemEnabled:YES error:&error];
        _lastAutoLaunchError = success ? nil : error;
        if (success) {
            [NSUserDefaults.standardUserDefaults setBool:YES forKey:AutoLaunchPreferenceKey];
        } else {
            NSAlert *alert = [NSAlert new];
            alert.messageText = @"无法启用登录启动";
            alert.informativeText = error.localizedDescription ?: @"请稍后重试。";
            [alert beginSheetModalForWindow:_settingsWindow completionHandler:nil];
        }
        [self updateAutoLaunchStatus];
    }
}

- (NSTextField *)labelWithText:(NSString *)text frame:(NSRect)frame font:(NSFont *)font color:(NSColor *)color {
    NSTextField *label = [NSTextField labelWithString:text];
    label.frame = frame;
    label.font = font;
    label.textColor = color;
    return label;
}

- (void)buildSettingsWindow {
    _settingsWindow = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(0, 0, 460, 350)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
        backing:NSBackingStoreBuffered
        defer:NO];
    _settingsWindow.title = @"网速设置";
    _settingsWindow.releasedWhenClosed = NO;
    _settingsWindow.collectionBehavior = NSWindowCollectionBehaviorMoveToActiveSpace;
    [_settingsWindow center];

    NSView *content = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 460, 350)];
    _settingsWindow.contentView = content;

    NSString *iconPath = [NSBundle.mainBundle pathForResource:@"AppIcon" ofType:@"icns"];
    NSImageView *iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(28, 250, 72, 72)];
    iconView.image = [[NSImage alloc] initWithContentsOfFile:iconPath];
    iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
    [content addSubview:iconView];

    NSTextField *name = [self labelWithText:@"网速菜单栏"
                                      frame:NSMakeRect(120, 286, 310, 30)
                                       font:[NSFont systemFontOfSize:22 weight:NSFontWeightSemibold]
                                      color:NSColor.labelColor];
    [content addSubview:name];

    NSTextField *tagline = [self labelWithText:@"实时显示上传与下载速度，不占用 Dock 空间。"
                                         frame:NSMakeRect(120, 252, 310, 38)
                                          font:[NSFont systemFontOfSize:13]
                                         color:NSColor.secondaryLabelColor];
    tagline.maximumNumberOfLines = 2;
    [content addSubview:tagline];

    NSBox *topSeparator = [[NSBox alloc] initWithFrame:NSMakeRect(28, 226, 404, 1)];
    topSeparator.boxType = NSBoxSeparator;
    [content addSubview:topSeparator];

    _autoLaunchButton = [NSButton checkboxWithTitle:@"登录后自动静默启动"
                                             target:self
                                             action:@selector(autoLaunchChanged:)];
    _autoLaunchButton.frame = NSMakeRect(28, 182, 260, 26);
    _autoLaunchButton.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    [content addSubview:_autoLaunchButton];

    _autoLaunchStatusLabel = [self labelWithText:@""
                                           frame:NSMakeRect(48, 153, 245, 22)
                                            font:[NSFont systemFontOfSize:12]
                                           color:NSColor.secondaryLabelColor];
    [content addSubview:_autoLaunchStatusLabel];

    _loginItemActionButton = [NSButton buttonWithTitle:@"打开登录项设置"
                                                target:self
                                                action:@selector(loginItemActionClicked:)];
    _loginItemActionButton.frame = NSMakeRect(302, 148, 130, 28);
    _loginItemActionButton.bezelStyle = NSBezelStyleRounded;
    _loginItemActionButton.font = [NSFont systemFontOfSize:12];
    _loginItemActionButton.hidden = YES;
    [content addSubview:_loginItemActionButton];

    NSBox *bottomSeparator = [[NSBox alloc] initWithFrame:NSMakeRect(28, 137, 404, 1)];
    bottomSeparator.boxType = NSBoxSeparator;
    [content addSubview:bottomSeparator];

    NSTextField *descriptionTitle = [self labelWithText:@"软件说明"
                                                  frame:NSMakeRect(28, 105, 100, 22)
                                                   font:[NSFont systemFontOfSize:13 weight:NSFontWeightSemibold]
                                                  color:NSColor.labelColor];
    [content addSubview:descriptionTitle];

    NSTextField *description = [self labelWithText:@"一款轻量级 macOS 菜单栏网速工具，每秒更新上传和下载速度；关闭设置窗口后仍会在菜单栏运行。"
                                             frame:NSMakeRect(28, 58, 404, 44)
                                              font:[NSFont systemFontOfSize:12.5]
                                             color:NSColor.secondaryLabelColor];
    description.maximumNumberOfLines = 2;
    description.lineBreakMode = NSLineBreakByWordWrapping;
    [content addSubview:description];

    NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.5";
    NSTextField *versionLabel = [self labelWithText:[NSString stringWithFormat:@"版本：%@", version]
                                              frame:NSMakeRect(28, 24, 180, 20)
                                               font:[NSFont systemFontOfSize:12]
                                              color:NSColor.tertiaryLabelColor];
    [content addSubview:versionLabel];

    NSTextField *authorLabel = [self labelWithText:@"作者：郭鹏"
                                             frame:NSMakeRect(150, 24, 165, 20)
                                              font:[NSFont systemFontOfSize:12]
                                             color:NSColor.tertiaryLabelColor];
    authorLabel.alignment = NSTextAlignmentRight;
    [content addSubview:authorLabel];

    NSButton *quitButton = [NSButton buttonWithTitle:@"退出网速"
                                              target:self
                                              action:@selector(quitApplication:)];
    quitButton.frame = NSMakeRect(338, 15, 94, 30);
    quitButton.bezelStyle = NSBezelStyleRounded;
    quitButton.toolTip = @"完全退出网速菜单栏程序";
    [content addSubview:quitButton];
}

- (void)showSettingsWindow {
    if (!_settingsWindow) [self buildSettingsWindow];
    [self updateAutoLaunchStatus];
    [NSApp activateIgnoringOtherApps:YES];
    [_settingsWindow makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [self showSettingsWindow];
    return YES;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self updateAutoLaunchStatus];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [NSAppleEventManager.sharedAppleEventManager
        removeEventHandlerForEventClass:kCoreEventClass
                              andEventID:kAEOpenApplication];
}

- (void)quitApplication:(id)sender {
    [NSApp terminate:nil];
}
@end

int main(void) {
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        AppDelegate *delegate = [AppDelegate new];
        app.delegate = delegate;
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [app run];
    }
    return 0;
}
