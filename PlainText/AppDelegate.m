//
//  AppDelegate.m
//  PlainText
//
//  Created by 王一凡 on 2017/9/17.
//  Copyright © 2017年 王一凡. All rights reserved.
//

#import "AppDelegate.h"
#import <Carbon/Carbon.h>

@interface AppDelegate ()

@end

//用于保存快捷键事件回调的引用，以便于可以注销
static EventHandlerRef g_EventHandlerRef = NULL;
//用于保存快捷键注册的引用，便于可以注销该快捷键
static EventHotKeyRef a_HotKeyRef = NULL;
static EventHotKeyRef b_HotKeyRef = NULL;
//快捷键注册使用的信息，用在回调中判断是哪个快捷键被触发
//a_HotKeyID代表cmd+C，自动清除
static EventHotKeyID a_HotKeyID = {'keyA',1};
//b_HotKeyID代表手动清除
static EventHotKeyID b_HotKeyID = {'keyB',2};

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
            //动作
        }
        if (keyID.id == b_HotKeyID.id) {
            
        }
    }
    return noErr;
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self registerHotKeyHandler];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [self unregisterAHotKey];
    [self unregisterBHotKey];
    [self unregisterHotKeyHandler];
}

//当指定cmd+C为热键时，原来的“复制”功能被屏蔽，因此需要重新编写复制函数
- (void)copySelectedText{
    CGEventRef copyEvent = CGEventCreateKeyboardEvent(NULL, kVK_ANSI_C, true);
    CGEventSetFlags(copyEvent, kCGEventFlagMaskCommand);
    //kCGAnnotatedSessionEventTap很重要，不会再触发热键
    CGEventPost(kCGAnnotatedSessionEventTap, copyEvent);
    CFRelease(copyEvent);
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
    //注册快捷键cmd+c
    RegisterEventHotKey(kVK_ANSI_C,
                        cmdKey,
                        a_HotKeyID,
                        GetApplicationEventTarget(),
                        0,
                        &a_HotKeyRef);
}

- (void)registerBHotKey{
    //注册快捷键cmd+shift+c
    RegisterEventHotKey(kVK_ANSI_B,
                        cmdKey|shiftKey,
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
