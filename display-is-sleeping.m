#import <Cocoa/Cocoa.h>
#import <signal.h>

NSString *appName;

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate

void signalHandler(int signal) {
    if (signal == SIGUSR1) {
        [NSApp terminate:nil];
    }
}

void printUsage() {
    const char *appNameCStr = [appName UTF8String];
    printf("A display sleep status check tool\n");
    printf("Usage: %s [options]\n", appNameCStr);
    printf("    --agent     initialize (meant to be used in a LaunchAgent)\n");
    printf("    --status    print 'true' if the screen is asleep, 'false' otherwise\n");
    printf("    without args, returns exit code 0 (true) or 1 (false) indicating the sleep status\n");
}

- (BOOL)isOtherInstanceRunning {
    int pid = getpid();
    BOOL isRunning = NO;
    NSString *cmd = [NSString stringWithFormat:@"pgrep -f %@", appName];
    FILE *fp = popen([cmd UTF8String], "r");
    if (fp) {
        char buf[10];
        while (fgets(buf, sizeof(buf), fp) != NULL) {
            int otherPid = atoi(buf);
            if (otherPid != pid) {
                isRunning = YES;
                break;
            }
        }
        pclose(fp);
    }
    return isRunning;
}

- (void)sendSignalToOtherInstances {
    int pid = getpid();
    NSString *cmd = [NSString stringWithFormat:@"pgrep -f %@", appName];
    FILE *fp = popen([cmd UTF8String], "r");
    if (fp) {
        char buf[10];
        while (fgets(buf, sizeof(buf), fp) != NULL) {
            int otherPid = atoi(buf);
            if (otherPid != pid) {
                kill(otherPid, SIGUSR1);
            }
        }
        pclose(fp);
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    signal(SIGUSR1, signalHandler);

    if ([arguments containsObject:@"-h"] || [arguments containsObject:@"--help"]) {
        printUsage();
        [NSApp terminate:nil];
        return;
    }
    if ([arguments containsObject:@"--agent"]) {
        [self sendSignalToOtherInstances];
        NSLog(@"starting up display sleep status agent");
        [defaults setObject:@"false" forKey:@"ScreenState"];
        [self setupBackgroundProcess];
    } else if ([arguments containsObject:@"--status"]) {
        if (![self isOtherInstanceRunning]) {
            fprintf(stderr, "agent not running\n");
            exit(1);
        }
        [self printStatus];
        [NSApp terminate:nil];
    } else {
        NSString *state = [defaults stringForKey:@"ScreenState"];
        BOOL isScreenAsleep = [state isEqualToString:@"true"];
        exit(isScreenAsleep ? 0 : 1);
    }
}

- (void)setupBackgroundProcess {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSNotificationCenter *center = [workspace notificationCenter];

    [center addObserver:self
               selector:@selector(screensDidSleep:)
                   name:NSWorkspaceScreensDidSleepNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(screensDidWake:)
                   name:NSWorkspaceScreensDidWakeNotification
                 object:nil];
}

- (void)printStatus {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *state = [defaults stringForKey:@"ScreenState"];
    printf("%s\n", [state UTF8String]);
}

- (void)updateScreenState:(BOOL)asleep {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *state = asleep ? @"true" : @"false";
    [defaults setObject:state forKey:@"ScreenState"];
}

- (void)screensDidSleep:(NSNotification *)notification {
    [self updateScreenState:YES];
}

- (void)screensDidWake:(NSNotification *)notification {
    [self updateScreenState:NO];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        appName = [[NSProcessInfo processInfo] processName];
        NSApplication *application = [NSApplication sharedApplication];
        AppDelegate *appDelegate = [[AppDelegate alloc] init];
        application.delegate = appDelegate;
        [application run];
    }
    return 0;
}
