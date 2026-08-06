// Require standard library
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#include <iostream>
#include <UIKit/UIKit.h>
#include <vector>
#import "pthread.h"
#include <array>
#import <os/log.h>
#include <cmath>
#include <deque>
#include <fstream>
#include <algorithm>
#include <string>
#include <sstream>
#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <cstdint>
#include <cinttypes>
#include <cerrno>
#include <cctype>

// Imgui library
#import "Esp/CaptainHook.h"
#import "Esp/ImGuiDrawView.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_internal.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/zzz.h"

ImFont* verdana_smol = nullptr;
ImFont* pixel_big = nullptr;
ImFont* pixel_smol = nullptr;

#include "oxorany/oxorany_include.h"
#import "Helper/Mem.h"
#import "Helper/Vector3.h"
#import "Helper/Vector2.h"
#import "Helper/Quaternion.h"
#import "Helper/Monostring.h"
#include "Helper/font.h"
#include "Helper/data.h"
#include "Helper/Obfuscate.h"

#import "Helper/Hooks.h"

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <unistd.h>
#include <string.h>
#include "Other/dobby_defines.h"
#import "Other/H5hook.h"
#include "Other/Paste.h"

#define Hook(x, y, z) \
{ \
    NSString* result_##y = StaticInlineHookPatch(("Frameworks/UnityFramework.framework/UnityFramework"), x, nullptr); \
    if (result_##y) { \
        void* result = StaticInlineHookFunction(("Frameworks/UnityFramework.framework/UnityFramework"), x, (void *) y); \
        *(void **) (&z) = (void*) result; \
    } \
}

static float fixLoginTimeout = 60.0f;
static bool MenDeal = true; // Auto open overlay on load

// 🔴 VIDEO EXACT RED ACCENT COLOR
static float menuAccentColor[3] = { 0.95f, 0.15f, 0.15f }; 
static float menuAlpha = 0.92f;
static int currentTab = 0; // 0: Aimbot, 1: Visuals, 2: Misc, 3: Settings

// --- LOGIN STATE VARIABLES ---
static bool isLoggedIn = false;
static bool isAuthenticating = false;
static char licenseKey[128] = "";
static std::string loginMessage = "Enter or Paste License Key to Access System";
static ImVec4 loginMsgColor = ImVec4(0.8f, 0.8f, 0.8f, 1.0f);
static std::string keyExpiryDate = "Pending...";
static bool apiConnected = false;

// Crash Timer
static bool shouldCrash = false;
static float crashTimer = 10.0f;

#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale

@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
- (void)authenticateKey:(NSString *)key;
- (void)logoutKey;
@end

@implementation ImGuiDrawView
ImFont *_espFont;
ImFont* verdanab;
ImFont* icons;
ImFont* interb;
ImFont* Urbanist;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];

    if (!self.device) abort();

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;

    // === EXACT VIDEO THEME SETUP (Sleek Dark Red Glass) ===
    ImGuiStyle& style = ImGui::GetStyle();
    style.Alpha = 1.0f;
    style.WindowRounding = 12.0f;     
    style.FrameRounding = 6.0f;
    style.ChildRounding = 8.0f;
    style.PopupRounding = 8.0f;
    style.ScrollbarRounding = 10.0f;
    style.GrabRounding = 6.0f;
    style.TabRounding = 6.0f;
    style.WindowBorderSize = 1.5f;
    style.FrameBorderSize = 1.0f;    
    style.WindowPadding = ImVec2(12.0f, 12.0f);
    style.ItemSpacing = ImVec2(8.0f, 8.0f);
    style.ItemInnerSpacing = ImVec2(6.0f, 6.0f);
    style.AntiAliasedLines = true;
    style.AntiAliasedFill = true;
    
    ImVec4* colors = style.Colors;
    colors[ImGuiCol_Text]                   = ImVec4(0.95f, 0.95f, 0.95f, 1.00f);
    colors[ImGuiCol_TextDisabled]           = ImVec4(0.50f, 0.50f, 0.55f, 1.00f);
    colors[ImGuiCol_WindowBg]               = ImVec4(0.06f, 0.06f, 0.08f, menuAlpha);
    colors[ImGuiCol_ChildBg]                = ImVec4(0.08f, 0.08f, 0.10f, 0.80f);
    colors[ImGuiCol_PopupBg]                = ImVec4(0.07f, 0.07f, 0.09f, 0.98f);
    colors[ImGuiCol_FrameBg]                = ImVec4(0.12f, 0.12f, 0.15f, 1.00f);
    colors[ImGuiCol_FrameBgHovered]         = ImVec4(0.18f, 0.18f, 0.22f, 1.00f);
    colors[ImGuiCol_TitleBg]                = ImVec4(0.06f, 0.06f, 0.08f, 1.00f);
    colors[ImGuiCol_TitleBgCollapsed]       = ImVec4(0.00f, 0.00f, 0.00f, 0.50f);
    colors[ImGuiCol_TitleBgActive]          = ImVec4(0.06f, 0.06f, 0.08f, 1.00f);
    colors[ImGuiCol_MenuBarBg]              = ImVec4(0.08f, 0.08f, 0.10f, 1.00f);
    colors[ImGuiCol_ScrollbarBg]            = ImVec4(0.02f, 0.02f, 0.03f, 0.40f);
    colors[ImGuiCol_ScrollbarGrab]          = ImVec4(0.25f, 0.25f, 0.30f, 1.00f);
    colors[ImGuiCol_Separator]              = ImVec4(0.20f, 0.20f, 0.25f, 1.00f);

    // Font loading
    ImFont* font = io.Fonts->AddFontFromMemoryTTF(sansbold, sizeof(sansbold), 16.0f, NULL, io.Fonts->GetGlyphRangesCyrillic());
    verdana_smol = io.Fonts->AddFontFromMemoryTTF(verdana, sizeof(verdana), 40, NULL, io.Fonts->GetGlyphRangesCyrillic());
    pixel_big = io.Fonts->AddFontFromMemoryTTF((void*)smallestpixel, sizeof(smallestpixel), 128, NULL, io.Fonts->GetGlyphRangesCyrillic());
    pixel_smol = io.Fonts->AddFontFromMemoryTTF((void*)smallestpixel, sizeof(smallestpixel), 20, NULL, io.Fonts->GetGlyphRangesCyrillic());
    
    ImGui_ImplMetal_Init(_device);

    return self;
}

+ (void)showChange:(BOOL)open
{
    MenDeal = open;
}

- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}

- (void)loadView
{
    CGRect bounds = [UIScreen mainScreen].bounds;
    self.view = [[MTKView alloc] initWithFrame:bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.mtkView.clipsToBounds = YES;
    self.mtkView.contentScaleFactor = [UIScreen mainScreen].scale;

    Hook(0x58B3258 , BLAGCMCGEJG1, old_BLAGCMCGEJG1);

    // Auto-login check on launch
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedLicenseKey"];
    if (savedKey && savedKey.length > 0) {
        strncpy(licenseKey, [savedKey UTF8String], sizeof(licenseKey) - 1);
        isAuthenticating = true;
        loginMessage = "Authenticating Saved License Key...";
        loginMsgColor = ImVec4(0.2f, 0.8f, 1.0f, 1.0f);
        [self authenticateKey:savedKey];
    }
}

- (void)logoutKey {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SavedLicenseKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    isLoggedIn = false;
    apiConnected = false;
    memset(licenseKey, 0, sizeof(licenseKey));
    loginMessage = "Logged Out Successfully.";
    loginMsgColor = ImVec4(0.9f, 0.6f, 0.2f, 1.0f);
}

- (void)authenticateKey:(NSString *)key {
    NSString *name = @"STATISTIC PRO";
    NSString *ownerid = @"wFY9t1Imun";
    NSString *version = @"1.0";
    
    NSString *initUrlStr = [NSString stringWithFormat:@"https://keyauth.win/api/1.2/?type=init&ver=%@&name=%@&ownerid=%@", version, [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], ownerid];
    
    NSMutableURLRequest *initReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:initUrlStr]];
    initReq.HTTPMethod = @"GET";
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:initReq completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (err || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                loginMessage = "Server Connection Failed! Closing in 10s...";
                loginMsgColor = ImVec4(1.0f, 0.2f, 0.2f, 1.0f);
                isAuthenticating = false;
                shouldCrash = true;
            });
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([json[@"success"] boolValue]) {
            NSString *sessionId = json[@"sessionid"];
            NSString *hwid = [[[UIDevice currentDevice] identifierForVendor] UUIDString]; 
            
            NSString *licUrlStr = [NSString stringWithFormat:@"https://keyauth.win/api/1.2/?type=license&key=%@&hwid=%@&sessionid=%@&name=%@&ownerid=%@", key, hwid, sessionId, [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], ownerid];
            
            NSMutableURLRequest *licReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:licUrlStr]];
            licReq.HTTPMethod = @"GET";
            
            [[[NSURLSession sharedSession] dataTaskWithRequest:licReq completionHandler:^(NSData *licData, NSURLResponse *licRes, NSError *licErr) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    isAuthenticating = false;
                    if (licErr || !licData) {
                        loginMessage = "API Error! Closing in 10s...";
                        loginMsgColor = ImVec4(1.0f, 0.2f, 0.2f, 1.0f);
                        shouldCrash = true;
                        return;
                    }
                    
                    NSDictionary *licJson = [NSJSONSerialization JSONObjectWithData:licData options:0 error:nil];
                    if ([licJson[@"success"] boolValue]) {
                        isLoggedIn = true;
                        apiConnected = true;
                        shouldCrash = false;
                        
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedLicenseKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                        loginMessage = "Login Successful!";
                        loginMsgColor = ImVec4(0.2f, 1.0f, 0.2f, 1.0f);
                        
                        NSDictionary *info = licJson[@"info"];
                        if (info && info[@"subscriptions"]) {
                            NSArray *subs = info[@"subscriptions"];
                            if (subs.count > 0) {
                                NSString *expiryTimestamp = subs[0][@"expiry"];
                                NSDate *date = [NSDate dateWithTimeIntervalSince1970:[expiryTimestamp doubleValue]];
                                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                keyExpiryDate = std::string([[formatter stringFromDate:date] UTF8String]);
                            }
                        }
                    } else {
                        NSString *msg = licJson[@"message"];
                        if ([msg containsString:@"invalid"]) loginMessage = "Invalid Key!";
                        else if ([msg containsString:@"hwid"]) loginMessage = "HWID Mismatch!";
                        else if ([msg containsString:@"used"]) loginMessage = "Key Already Used!";
                        else loginMessage = std::string([msg UTF8String]);
                        
                        loginMsgColor = ImVec4(1.0f, 0.2f, 0.2f, 1.0f);
                        shouldCrash = true;
                    }
                });
            }] resume];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                loginMessage = "Init Failed! Closing in 10s...";
                loginMsgColor = ImVec4(1.0f, 0.2f, 0.2f, 1.0f);
                isAuthenticating = false;
                shouldCrash = true;
            });
        }
    }] resume];
}

#pragma mark - Interaction

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.nativeScale ?: UIScreen.mainScreen.nativeScale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1.0f / float(view.preferredFramesPerSecond ?: 60);

    if (shouldCrash) {
        crashTimer -= io.DeltaTime;
        if (crashTimer <= 0.0f) {
            exit(0);
        }
    }

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    [self.view setUserInteractionEnabled:(!isLoggedIn ? YES : MenDeal)];

    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui Main View"];

        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();
        
        ImGuiStyle& style = ImGui::GetStyle();
        style.Colors[ImGuiCol_WindowBg].w = menuAlpha;
        
        ImVec4 accent = ImVec4(menuAccentColor[0], menuAccentColor[1], menuAccentColor[2], 1.0f);
        ImVec4 accent_hover = ImVec4(menuAccentColor[0] * 1.15f, menuAccentColor[1] * 1.15f, menuAccentColor[2] * 1.15f, 1.0f);
        ImVec4 accent_active = ImVec4(menuAccentColor[0] * 0.85f, menuAccentColor[1] * 0.85f, menuAccentColor[2] * 0.85f, 1.0f);
        ImVec4 accent_dim = ImVec4(menuAccentColor[0], menuAccentColor[1], menuAccentColor[2], 0.35f);

        style.Colors[ImGuiCol_Border]                 = accent;
        style.Colors[ImGuiCol_CheckMark]              = accent;
        style.Colors[ImGuiCol_SliderGrab]             = accent;
        style.Colors[ImGuiCol_SliderGrabActive]       = accent_active;
        style.Colors[ImGuiCol_Button]                 = ImVec4(0.12f, 0.12f, 0.15f, 1.0f);
        style.Colors[ImGuiCol_ButtonHovered]          = accent_dim;
        style.Colors[ImGuiCol_ButtonActive]           = accent;

        if (!isLoggedIn || MenDeal)
        {
            // =========================================================
            //  🔐 KEY AUTH UI (EXACT LAYOUT FROM VIDEO)
            // =========================================================
            if (!isLoggedIn) {
                ImGui::SetNextWindowSize(ImVec2(440, 240), ImGuiCond_Always);
                ImGui::SetNextWindowPos(ImVec2((io.DisplaySize.x - 440) / 2, (io.DisplaySize.y - 240) / 2), ImGuiCond_Always);
                
                ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1.5f);
                ImGui::Begin("AuthUI", NULL, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoSavedSettings);
                
                ImVec2 size = ImGui::GetWindowSize();
                
                // Title
                ImGui::SetCursorPosY(18);
                ImGui::SetWindowFontScale(1.2f);
                ImGui::SetCursorPosX((size.x - ImGui::CalcTextSize("STATISTICS KING").x) / 2);
                ImGui::TextColored(accent, "STATISTICS KING");
                
                ImGui::SetWindowFontScale(0.9f);
                ImGui::SetCursorPosX((size.x - ImGui::CalcTextSize("PREMIUM ACCESS").x) / 2);
                ImGui::TextDisabled("PREMIUM ACCESS");
                ImGui::SetWindowFontScale(1.0f);
                
                ImGui::Spacing();
                
                // Status Message
                if (shouldCrash) {
                    char crashMsg[128];
                    snprintf(crashMsg, sizeof(crashMsg), "Access Denied! Game closing in %.1f s...", crashTimer);
                    ImGui::SetCursorPosX((size.x - ImGui::CalcTextSize(crashMsg).x) / 2);
                    ImGui::TextColored(ImVec4(1.0f, 0.2f, 0.2f, 1.0f), "%s", crashMsg);
                } else {
                    ImGui::SetCursorPosX((size.x - ImGui::CalcTextSize(loginMessage.c_str()).x) / 2);
                    ImGui::TextColored(loginMsgColor, "%s", loginMessage.c_str());
                }
                
                ImGui::Spacing();
                ImGui::Separator();
                ImGui::Spacing();
                
                // Key Input Field with Clear Button
                ImGui::Text(" License Key:");
                ImGui::SetNextItemWidth(size.x - 110);
                ImGui::InputTextWithHint("##KeyInput", "Paste Key Here...", licenseKey, IM_ARRAYSIZE(licenseKey), ImGuiInputTextFlags_Password);
                
                ImGui::SameLine();
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.6f, 0.15f, 0.15f, 0.8f));
                if (ImGui::Button("Clear", ImVec2(70, 26))) {
                    memset(licenseKey, 0, sizeof(licenseKey));
                    loginMessage = "Cleared!";
                    loginMsgColor = ImVec4(0.8f, 0.8f, 0.8f, 1.0f);
                }
                ImGui::PopStyleColor();
                
                ImGui::Spacing();
                ImGui::Spacing();
                
                // Login Action Buttons
                ImGui::SetCursorPosX(20);
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.15f, 0.40f, 0.75f, 0.85f));
                if (ImGui::Button("Paste Key", ImVec2(180, 36))) {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    if (pasteboard.string) {
                        strncpy(licenseKey, pasteboard.string.UTF8String, sizeof(licenseKey) - 1);
                        loginMessage = "Key Pasted! Click Login.";
                        loginMsgColor = ImVec4(0.4f, 0.9f, 0.4f, 1.0f);
                    }
                }
                ImGui::PopStyleColor();
                
                ImGui::SameLine();
                
                ImGui::PushStyleColor(ImGuiCol_Button, accent);
                ImGui::PushStyleColor(ImGuiCol_ButtonHovered, accent_hover);
                ImGui::PushStyleColor(ImGuiCol_ButtonActive, accent_active);
                if (ImGui::Button(isAuthenticating ? "Authenticating..." : "Login to System", ImVec2(200, 36))) {
                    if (!isAuthenticating && !shouldCrash) {
                        if (strlen(licenseKey) > 0) {
                            isAuthenticating = true;
                            loginMessage = "Connecting to KeyAuth...";
                            loginMsgColor = ImVec4(1.0f, 0.8f, 0.2f, 1.0f);
                            [self authenticateKey:[NSString stringWithUTF8String:licenseKey]];
                        } else {
                            loginMessage = "Please Enter or Paste a Key!";
                            loginMsgColor = ImVec4(1.0f, 0.3f, 0.3f, 1.0f);
                        }
                    }
                }
                ImGui::PopStyleColor(3);
                
                ImGui::End();
                ImGui::PopStyleVar();
            }
            // =========================================================
            //  🎮 MAIN MOD MENU (EXACT LOOK FROM VIDEO - SIDEBAR TABS)
            // =========================================================
            else 
            {                
                ImGui::SetNextWindowSize(ImVec2(620, 380), ImGuiCond_FirstUseEver);
                ImGui::SetNextWindowPos(ImVec2((io.DisplaySize.x - 620) / 2, (io.DisplaySize.y - 380) / 2), ImGuiCond_FirstUseEver);
                
                ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1.5f);
                ImGui::Begin("STATISTICS KING", &MenDeal, ImGuiWindowFlags_NoCollapse);
                
                // Left Navigation Sidebar (Video Layout)
                ImGui::BeginChild("Sidebar", ImVec2(150, 0), true);
                
                ImGui::SetCursorPosY(15);
                ImGui::TextColored(accent, " STATISTICS KING");
                ImGui::Separator();
                ImGui::Spacing();
                
                // Sidebar Tab Buttons
                #define DRAW_TAB_BTN(name, index) \
                    if (currentTab == index) { \
                        ImGui::PushStyleColor(ImGuiCol_Button, accent); \
                    } else { \
                        ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.10f, 0.10f, 0.12f, 0.6f)); \
                    } \
                    if (ImGui::Button(name, ImVec2(130, 36))) { currentTab = index; } \
                    ImGui::PopStyleColor(); \
                    ImGui::Spacing();

                DRAW_TAB_BTN("  Aimbot", 0);
                DRAW_TAB_BTN("  Visuals", 1);
                DRAW_TAB_BTN("  Misc", 2);
                DRAW_TAB_BTN("  Settings", 3);
                
                ImGui::EndChild();
                
                ImGui::SameLine();
                
                // Right Content View
                ImGui::BeginChild("ContentArea", ImVec2(0, 0), true);
                
                // --- TAB 0: AIMBOT ---
                if (currentTab == 0) {
                    ImGui::TextColored(accent, "AIMBOT CONFIGURATION");
                    ImGui::Separator();
                    ImGui::Spacing();

                    ImGui::Checkbox("Master Switch", &Vars.Aimbot);
                    
                    ImGui::SetNextItemWidth(220);
                    ImGui::Combo("Aimbot Config", &Vars.AimWhen, Vars.dir, 4);
                    
                    ImGui::Checkbox("Enabled", &SilentAim);
                    
                    ImGui::SetNextItemWidth(220);
                    ImGui::Combo("Aiming Method", &Vars.AimMode, Vars.aimModes, 3);
                    
                    ImGui::Checkbox("Show FOV Circle", &Vars.isAimFov);
                    ImGui::Checkbox("Ignore Knocked", &Vars.IgnoreKnocked);
                    ImGui::Checkbox("Check Wall", &CheckWall1);
                    
                    ImGui::SetNextItemWidth(220);
                    ImGui::Combo("Hitbox Target", &Vars.AimHitbox, Vars.aimHitboxes, 3);
                    
                    ImGui::SetNextItemWidth(260);
                    ImGui::SliderFloat("FOV", &Vars.AimFov, 0.0f, 360.0f, "%.1f Deg");
                }
                
                // --- TAB 1: VISUALS ---
                else if (currentTab == 1) {
                    ImGui::TextColored(accent, "VISUALS & ESP");
                    ImGui::Separator();
                    ImGui::Spacing();

                    ImGui::Checkbox("Enemy ESP", &Vars.Enable);
                    ImGui::Checkbox("Line", &Vars.lines);
                    ImGui::Checkbox("Box", &Vars.Box);
                    ImGui::Checkbox("Health", &Vars.Health);
                    ImGui::Checkbox("Nickname", &Vars.Name);
                    ImGui::Checkbox("Distance", &Vars.Distance);
                    ImGui::Checkbox("Skeleton", &Vars.skeleton);
                    ImGui::Checkbox("3D Circle", &Vars.circlepos);
                    ImGui::Checkbox("Nearby Enemies Count", &Vars.enemycount);
                }
                
                // --- TAB 2: MISC ---
                else if (currentTab == 2) {
                    ImGui::TextColored(accent, "MISC FUNCTIONS");
                    ImGui::Separator();
                    ImGui::Spacing();

                    ImGui::Checkbox("Out of Screen Warning", &Vars.OOF);
                    ImGui::Checkbox("Enemy Outline", &Vars.Outline);
                }
                
                // --- TAB 3: SETTINGS ---
                else if (currentTab == 3) {
                    ImGui::TextColored(accent, "SYSTEM & THEME SETTINGS");
                    ImGui::Separator();
                    ImGui::Spacing();

                    ImGui::Text("API Server:");
                    ImGui::SameLine(130);
                    ImGui::TextColored(apiConnected ? ImVec4(0.2f, 1.0f, 0.2f, 1.0f) : ImVec4(1.0f, 0.2f, 0.2f, 1.0f), apiConnected ? "CONNECTED" : "DISCONNECTED");

                    ImGui::Text("License Key:");
                    ImGui::SameLine(130);
                    std::string keyStr = std::string(licenseKey);
                    std::string maskedKey = keyStr;
                    if (keyStr.length() > 8) {
                        maskedKey = keyStr.substr(0, 4) + "********" + keyStr.substr(keyStr.length() - 4);
                    }
                    ImGui::TextColored(accent, "%s", maskedKey.c_str());

                    ImGui::Text("Subscription:");
                    ImGui::SameLine(130);
                    ImGui::TextColored(accent, "%s", keyExpiryDate.c_str());

                    ImGui::Spacing();
                    
                    // Logout Account Button
                    ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.75f, 0.18f, 0.18f, 0.8f));
                    if (ImGui::Button("Logout Account", ImVec2(160, 32))) {
                        [self logoutKey];
                    }
                    ImGui::PopStyleColor();

                    ImGui::Spacing();
                    ImGui::Separator();
                    ImGui::Spacing();

                    ImGui::SetNextItemWidth(200);
                    ImGui::ColorEdit3("Menu Accent Color", menuAccentColor, ImGuiColorEditFlags_NoInputs);
                    
                    ImGui::SetNextItemWidth(200);
                    ImGui::SliderFloat("Menu Transparency", &menuAlpha, 0.20f, 1.00f, "%.2f");

                    ImGui::Spacing();
                    ImGui::Separator();
                    ImGui::Spacing();

                    if (ImGui::Button("Execute Fix Login", ImVec2(160, 30))) {
                        self.view.hidden = YES; 
                        MenDeal = false; 
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fixLoginTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            self.view.hidden = NO; 
                            MenDeal = true; 
                        });
                    }
                    ImGui::SameLine();
                    ImGui::SetNextItemWidth(140);
                    ImGui::SliderFloat("##fixlogin", &fixLoginTimeout, 40.0f, 80.0f, "Timeout: %.0f s");
                }
                
                ImGui::EndChild();
                
                ImGui::End();
                ImGui::PopStyleVar();
            }
        }
        
        // --- Game Drawing & Logic Calls ---
        ImDrawList* draw_list = ImGui::GetBackgroundDrawList();
        get_players();
        draw_watermark();
        aimbot();
        
        if (game_sdk) {
            game_sdk->init();
        }

        Vars.isAimFov = (Vars.AimFov > 0);

        ImGui::Render();
        ImDrawData* draw_data = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
      
        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size
{
    
}

@end
