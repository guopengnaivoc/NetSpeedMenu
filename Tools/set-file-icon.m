#import <AppKit/AppKit.h>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 3) return 2;
        NSString *iconPath = [NSString stringWithUTF8String:argv[1]];
        NSString *targetPath = [NSString stringWithUTF8String:argv[2]];
        NSImage *icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
        if (!icon) return 3;
        return [NSWorkspace.sharedWorkspace setIcon:icon forFile:targetPath options:0] ? 0 : 4;
    }
}
