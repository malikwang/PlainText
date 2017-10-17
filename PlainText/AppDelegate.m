//
//  AppDelegate.m
//  PlainText
//
//  Created by 王一凡 on 2017/9/17.
//  Copyright © 2017年 王一凡. All rights reserved.
//

#import "AppDelegate.h"
#import <Carbon/Carbon.h>
#import "NSString+IATitlecase.h"

@interface AppDelegate ()
//必须设置为全局变量，否则会一闪而过
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSMenu *menu;
@end

//用于保存快捷键事件回调的引用，以便于可以注销
static EventHandlerRef g_EventHandlerRef = NULL;
//用于保存快捷键注册的引用，便于可以注销该快捷键
static EventHotKeyRef a_HotKeyRef = NULL;
static EventHotKeyRef b_HotKeyRef = NULL;
static EventHotKeyRef c_HotKeyRef = NULL;
//快捷键注册使用的信息，用在回调中判断是哪个快捷键被触发
//a_HotKeyID代表cmd+V，自动清除
static EventHotKeyID a_HotKeyID = {'keyA',1};
//b_HotKeyID代表手动清除
static EventHotKeyID b_HotKeyID = {'keyB',2};
//c_HotKeyRef代表英文标题
//记录是否格式化标题
static BOOL titleCase = true;

//编一个C语言格式的函数，与- (void)removeFormatter一样，为的是myHotKeyHandler调用
void removeFormatter(){
    BOOL isText = true;
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    for (NSPasteboardItem *item in pasteboard.pasteboardItems) {
        for (NSString *type in item.types) {
            NSLog(@"%@",type);
            //以后可以不断添加条件：文件、图片、word软件内
            if ([type isEqualToString:@"public.file-url"] | [type isEqualToString:@"public.tiff"] | [type containsString:@"microsoft"] | [type containsString:@"png"]) {
                isText = false;
                break;
            }
        }
    }
    if (isText) {
        NSString *plainText = [[pasteboard readObjectsForClasses:@[[NSString class]] options:nil] firstObject];
        if (titleCase) {
            plainText = plainText.titlecaseString;
        }
        //写入剪切板
        [pasteboard clearContents];
        [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pasteboard setString:plainText forType:NSStringPboardType];
    } else {
        NSLog(@"文件");
    }
}
//当指定cmd+C为热键时，原来的“复制”功能被屏蔽，因此需要重新编写复制函数
void copySelectedText(){
    //在finder中也能使用
    CGEventSourceRef src = CGEventSourceCreate(kCGEventSourceStatePrivate);
    CGEventRef copyEvent = CGEventCreateKeyboardEvent(src, kVK_ANSI_C, true);
    CGEventSetFlags(copyEvent, kCGEventFlagMaskCommand);
    //kCGAnnotatedSessionEventTap很重要，不会再触发热键
    CGEventPost(kCGAnnotatedSessionEventTap, copyEvent);
    CFRelease(copyEvent);
    //CGEventPost有延迟
    sleep(1);
}

//当指定cmd+v为热键时，原来的“粘贴”功能被屏蔽，因此需要重新编写
void pasteText(){
    //在finder中也能使用
    CGEventSourceRef src = CGEventSourceCreate(kCGEventSourceStatePrivate);
    CGEventRef copyEvent = CGEventCreateKeyboardEvent(src, kVK_ANSI_V, true);
    CGEventSetFlags(copyEvent, kCGEventFlagMaskCommand);
    //kCGAnnotatedSessionEventTap很重要，不会再触发热键
    CGEventPost(kCGAnnotatedSessionEventTap, copyEvent);
    CFRelease(copyEvent);
    //CGEventPost有延迟
    sleep(1);
}

//快捷键的回调方法
OSStatus myHotKeyHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData){
    //判定事件的类型是否与所注册的一致
    if (GetEventClass(inEvent) == kEventClassKeyboard && GetEventKind(inEvent) == kEventHotKeyPressed){
        //获取快捷键信息，以判定是哪个快捷键被触发
        EventHotKeyID keyID;
        GetEventParameter(inEvent,
                          kEventParamDirectObject,
                          typeEventHotKeyID,
                          NULL,
                          sizeof(keyID),
                          NULL,
                          &keyID);
        if (keyID.id == a_HotKeyID.id) {
//            copySelectedText();
            removeFormatter();
            pasteText();
        }
        if (keyID.id == b_HotKeyID.id) {
            removeFormatter();
        }
    }
    return noErr;
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setHighlightMode:YES];
    [_statusItem setImage:[NSImage imageNamed:@"itemImage_normal"]];
    //高亮切换图标
    [_statusItem setAlternateImage:[NSImage imageNamed:@"itemImage_highlight"]];
    _menu = [[NSMenu alloc] init];
    
    //手动清除
    NSMenuItem *manualRemove = [[NSMenuItem alloc] initWithTitle:@"清除剪切板格式" action:@selector(removeFormatter) keyEquivalent:@"z"];
    //添加快捷键
    [manualRemove setKeyEquivalentModifierMask: NSEventModifierFlagOption | NSEventModifierFlagCommand];
    [_menu addItem:manualRemove];
    
    //自动清除
    NSMenuItem *autoRemove = [[NSMenuItem alloc] initWithTitle:@"自动清除" action:@selector(toggleState:) keyEquivalent:@""];
    [_menu addItem:autoRemove];
    
    //英文标题格式化
    _titleCaseItem = [[NSMenuItem alloc] initWithTitle:@"英文标题格式化" action:@selector(titleCase:) keyEquivalent:@""];
    [_menu addItem:_titleCaseItem];
    
    [_menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出" action:@selector(terminate:) keyEquivalent:@"q"];
    [_menu addItem:quit];
    
    [_statusItem setMenu:_menu];
    [self registerHotKeyHandler];
    [self registerBHotKey];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [self unregisterAHotKey];
    [self unregisterBHotKey];
    [self unregisterHotKeyHandler];
}

- (void)removeFormatter{
    BOOL isText = true;
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    for (NSPasteboardItem *item in pasteboard.pasteboardItems) {
        for (NSString *type in item.types) {
            NSLog(@"%@",type);
            //以后可以不断添加条件：文件、图片、word软件内
            if ([type isEqualToString:@"public.file-url"] | [type isEqualToString:@"public.tiff"] | [type containsString:@"microsoft"] | [type containsString:@"png"]) {
                isText = false;
                break;
            }
        }
    }
    if (isText) {
        NSString *plainText = [[pasteboard readObjectsForClasses:@[[NSString class]] options:nil] firstObject];
        if (titleCase) {
            plainText = plainText.titlecaseString;
        }
        //写入剪切板
        [pasteboard clearContents];
        [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pasteboard setString:plainText forType:NSStringPboardType];
    } else {
        NSLog(@"文件");
    }
}

- (void)titleCase:(NSMenuItem *)item{
    if (item.state == 0) {
        item.state = 1;
        titleCase = true;
    } else {
        item.state = 0;
        titleCase = false;
    }
}

- (void)toggleState:(NSMenuItem *)item{
    if (item.state == 0) {
        item.state = 1;
        [self registerAHotKey];
    } else {
        item.state = 0;
        [self unregisterAHotKey];
    }
}

- (void)registerHotKeyHandler{
    //注册快捷键的事件回调
    EventTypeSpec eventSpecs[] = {{kEventClassKeyboard,kEventHotKeyPressed}};
    InstallApplicationEventHandler(NewEventHandlerUPP(myHotKeyHandler),
                                   GetEventTypeCount(eventSpecs),
                                   eventSpecs,
                                   NULL,
                                   &g_EventHandlerRef);
}

- (void)registerAHotKey{
    //注册快捷键cmd+v
    RegisterEventHotKey(kVK_ANSI_V,
                        cmdKey,
                        a_HotKeyID,
                        GetApplicationEventTarget(),
                        0,
                        &a_HotKeyRef);
}

- (void)registerBHotKey{
    //注册快捷键cmd+option+z
    RegisterEventHotKey(kVK_ANSI_Z,
                        cmdKey|optionKey,
                        b_HotKeyID,
                        GetApplicationEventTarget(),
                        0,
                        &b_HotKeyRef);
}

- (void)unregisterAHotKey{
    if (a_HotKeyRef){
        UnregisterEventHotKey(a_HotKeyRef);
        a_HotKeyRef = NULL;
    }
}

- (void)unregisterBHotKey{
    if (b_HotKeyRef){
        UnregisterEventHotKey(b_HotKeyRef);
        b_HotKeyRef = NULL;
    }
}

- (void)unregisterHotKeyHandler{
    //注销快捷键的事件回调
    if (g_EventHandlerRef){
        RemoveEventHandler(g_EventHandlerRef);
        g_EventHandlerRef = NULL;
    }
}

@end
