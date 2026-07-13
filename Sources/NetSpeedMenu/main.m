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
        _uploadLabel = [NSTextField labelWithString:@"↑0B/s"];
        _downloadLabel = [NSTextField labelWithString:@"↓0B/s"];
        for (NSTextField *label in @[_uploadLabel, _downloadLabel]) {
            label.font = [NSFont monospacedDigitSystemFontOfSize:8.5 weight:NSFontWeightMedium];
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

- (void)mouseDown:(NSEvent *)event {}

+ (NSString *)formatSpeed:(double)value {
    NSArray<NSString *> *units = @[@"B/s", @"K/s", @"M/s", @"G/s"];
    value = MAX(0, value);
    NSUInteger index = 0;
    while (value >= 1000 && index < units.count - 1) {
        value /= 1000;
        index++;
    }
    if (index == 0) return [NSString stringWithFormat:@"%.0f%@", value, units[index]];
    if (value >= 100) return [NSString stringWithFormat:@"%.0f%@", value, units[index]];
    if (value >= 10) return [NSString stringWithFormat:@"%.1f%@", value, units[index]];
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
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    _statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:57];
    _speedView = [[SpeedView alloc] initWithFrame:NSMakeRect(0, 0, 57, NSStatusBar.systemStatusBar.thickness)];
    _speedView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [_statusItem.button addSubview:_speedView];
    _statusItem.button.enabled = NO;
    [_speedView updateUpload:0 download:0];

    _previous = ReadNetworkTotals();
    _previousDate = NSDate.date;

    [self applyStoredAutoLaunchPreference];
    _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];

    NSAppleEventDescriptor *event = NSAppleEventManager.sharedAppleEventManager.currentAppleEvent;
    BOOL launchedAsLoginItem = [event paramDescriptorForKeyword:keyAELaunchedAsLogInItem] != nil;
    if (!launchedAsLoginItem) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showSettingsWindow];
        });
    }
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
    id storedValue = [defaults objectForKey:@"AutoLaunchEnabled"];
    BOOL shouldEnable = storedValue ? [storedValue boolValue] : YES;
    if (!storedValue) [defaults setBool:YES forKey:@"AutoLaunchEnabled"];

    NSError *error = nil;
    [self setLoginItemEnabled:shouldEnable error:&error];
}

- (void)autoLaunchChanged:(NSButton *)sender {
    BOOL shouldEnable = sender.state == NSControlStateValueOn;
    NSError *error = nil;
    BOOL success = [self setLoginItemEnabled:shouldEnable error:&error];

    if (success) {
        [NSUserDefaults.standardUserDefaults setBool:shouldEnable forKey:@"AutoLaunchEnabled"];
    } else {
        sender.state = shouldEnable ? NSControlStateValueOff : NSControlStateValueOn;
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"无法修改开机启动设置";
        alert.informativeText = error.localizedDescription ?: @"请稍后重试。";
        [alert beginSheetModalForWindow:_settingsWindow completionHandler:nil];
    }
    [self updateAutoLaunchStatus];
}

- (void)updateAutoLaunchStatus {
    if (!_autoLaunchButton || !_autoLaunchStatusLabel) return;

    BOOL desired = [NSUserDefaults.standardUserDefaults boolForKey:@"AutoLaunchEnabled"];
    _autoLaunchButton.state = desired ? NSControlStateValueOn : NSControlStateValueOff;

    if (@available(macOS 13.0, *)) {
        switch (SMAppService.mainAppService.status) {
            case SMAppServiceStatusEnabled:
                _autoLaunchStatusLabel.stringValue = @"已启用：登录后仅在菜单栏静默运行";
                _autoLaunchStatusLabel.textColor = NSColor.secondaryLabelColor;
                break;
            case SMAppServiceStatusRequiresApproval:
                _autoLaunchStatusLabel.stringValue = @"需要在“系统设置 → 通用 → 登录项”中允许";
                _autoLaunchStatusLabel.textColor = NSColor.systemOrangeColor;
                break;
            case SMAppServiceStatusNotRegistered:
                _autoLaunchStatusLabel.stringValue = @"已关闭：登录系统时不会自动启动";
                _autoLaunchStatusLabel.textColor = NSColor.secondaryLabelColor;
                break;
            case SMAppServiceStatusNotFound:
                _autoLaunchStatusLabel.stringValue = @"暂时无法读取登录项状态";
                _autoLaunchStatusLabel.textColor = NSColor.systemRedColor;
                break;
        }
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

    _autoLaunchButton = [NSButton checkboxWithTitle:@"开机自动静默启动"
                                             target:self
                                             action:@selector(autoLaunchChanged:)];
    _autoLaunchButton.frame = NSMakeRect(28, 182, 260, 26);
    _autoLaunchButton.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    [content addSubview:_autoLaunchButton];

    _autoLaunchStatusLabel = [self labelWithText:@""
                                           frame:NSMakeRect(48, 156, 380, 22)
                                            font:[NSFont systemFontOfSize:12]
                                           color:NSColor.secondaryLabelColor];
    [content addSubview:_autoLaunchStatusLabel];

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

    NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.2";
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

- (void)quitApplication:(id)sender {
    [NSApp terminate:nil];
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        AppDelegate *delegate = [AppDelegate new];
        app.delegate = delegate;
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [app run];
    }
    return 0;
}
