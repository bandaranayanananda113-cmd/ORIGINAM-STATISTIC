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

// 🔴 PREMIUM NEON ACCENT COLORS & ANIMATION TIME
static float menuAccentColor[3] = { 0.00f, 0.75f, 1.00f }; 
static float animTime = 0.0f;

// --- LOGIN STATE VARIABLES ---
static bool isLoggedIn = false;
static bool isAuthenticating = false;
static char licenseKey[128] = "";
static std::string loginMessage = "Enter or Paste your License Key";
static ImVec4 loginMsgColor = ImVec4(0.8f, 0.8f, 0.8f, 1.0f);
static std::string keyExpiryDate = "Pending...";
static bool apiConnected = false;

// Crash Timer Variables
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

    // === MODERN DARK GLASS STYLE ===
    ImGuiStyle& style = ImGui::GetStyle();
    style.Alpha = 1.0f;
    style.WindowRounding = 12.0f;     
    style.FrameRounding = 6.0f;
    style.ChildRounding = 8.0f;
    style.PopupRounding = 8.0f;
    style.ScrollbarRounding = 12.0f;
    style.GrabRounding = 6.0f;
    style.TabRounding = 6.0f;
    style.WindowBorderSize = 1.0f;
    style.FrameBorderSize = 1.0f;    
    style.WindowPadding = ImVec2(16.0f, 16.0f);
    style.ItemSpacing = ImVec2(10.0f, 10.0f);
    style.ItemInnerSpacing = ImVec2(6.0f, 6.0f);
    style.AntiAliasedLines = true;
    style.AntiAliasedFill = true;
    
    ImVec4* colors = style.Colors;
    colors[ImGuiCol_Text]                   = ImVec4(0.95f, 0.96f, 0.98f, 1.00f);
    colors[ImGuiCol_TextDisabled]           = ImVec4(0.50f, 0.52f, 0.58f, 1.00f);
    colors[ImGuiCol_WindowBg]               = ImVec4(0.07f, 0.08f, 0.11f, 0.96f);
    colors[ImGuiCol_ChildBg]                = ImVec4(0.10f, 0.11f, 0.15f, 0.85f);
    colors[ImGuiCol_PopupBg]                = ImVec4(0.08f, 0.09f, 0.12f, 0.98f);
    colors[ImGuiCol_FrameBg]                = ImVec4(0.13f, 0.15f, 0.20f, 1.00f);
    colors[ImGuiCol_FrameBgHovered]         = ImVec4(0.18f, 0.21f, 0.28f, 1.00f);
    colors[ImGuiCol_TitleBg]                = ImVec4(0.07f, 0.08f, 0.11f, 1.00f);
    colors[ImGuiCol_TitleBgCollapsed]       = ImVec4(0.00f, 0.00f, 0.00f, 0.50f);
    colors[ImGuiCol_TitleBgActive]          = ImVec4(0.07f, 0.08f, 0.11f, 1.00f);
    colors[ImGuiCol_MenuBarBg]              = ImVec4(0.10f, 0.11f, 0.14f, 1.00f);
    colors[ImGuiCol_ScrollbarBg]            = ImVec4(0.03f, 0.04f, 0.05f, 0.50f);
    colors[ImGuiCol_ScrollbarGrab]          = ImVec4(0.22f, 0.25f, 0.32f, 1.00f);
    colors[ImGuiCol_Separator]              = ImVec4(0.18f, 0.20f, 0.26f, 1.00f);

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

    // --- AUTO LOAD SAVED KEY ON STARTUP ---
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedLicenseKey"];
    if (savedKey && savedKey.length > 0) {
        strncpy(licenseKey, [savedKey UTF8String], sizeof(licenseKey) - 1);
        isAuthenticating = true;
        loginMessage = "Auto Authenticatiing Saved Key...";
        loginMsgColor = ImVec4(0.2f, 0.8f, 1.0f, 1.0f);
        [self authenticateKey:savedKey];
    }
}

// --- LOGOUT FUNCTION ---
- (void)logoutKey {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SavedLicenseKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    isLoggedIn = false;
    apiConnected = false;
    memset(licenseKey, 0, sizeof(licenseKey));
    loginMessage = "Logged Out. Please enter a key.";
    loginMsgColor = ImVec4(0.9f, 0.6f, 0.2f, 1.0f);
}

// --- NATIVE KEYAUTH API ---
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
                loginMessage = "Connection Failed! Game crashing in 10s...";
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
                        loginMessage = "API Error! Game crashing in 10s...";
                        loginMsgColor = ImVec4(1.0f, 0.2f, 0.2f, 1.0f);
                        shouldCrash = true;
                        return;
                    }
                    
                    NSDictionary *licJson = [NSJSONSerialization JSONObjectWithData:licData options:0 error:nil];
                    if ([licJson[@"success"] boolValue]) {
                        isLoggedIn = true;
                        apiConnected = true;
                        shouldCrash = false;
                        
                        // Save key locally on success
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
                        // Key verification failed -> Trigger 10s Crash
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
                loginMessage = "Init Failed! Game crashing in 10s...";
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
    
    animTime += io.DeltaTime * 2.0f;

    // --- CRASH COUNTDOWN LOGIC ---
    if (shouldCrash) {
        crashTimer -= io.DeltaTime;
        if (crashTimer <= 0.0f) {
            exit(0); // Exit / Crash App
        }
    }

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    // Always keep touch enabled if not logged in to force key auth screen interaction
    [self.view setUserInteractionEnabled:(!isLoggedIn ? YES : MenDeal)];

    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui Main View"];

        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();
        
        float glowPulse = (sinf(animTime) + 1.0f) * 0.5f; 
        ImGuiStyle& style = ImGui::GetStyle();
        ImVec4 accent = ImVec4(menuAccentColor[0], menuAccentColor[1], menuAccentColor[2], 1.0f);
        ImVec4 accent_hover = ImVec4(menuAccentColor[0] * 1.2f, menuAccentColor[1] * 1.2f, menuAccentColor[2] * 1.2f, 1.0f);
        ImVec4 accent_active = ImVec4(menuAccentColor[0] * 0.8f, menuAccentColor[1] * 0.8f, menuAccentColor[2] * 0.8f, 1.0f);
        ImVec4 accent_dim = ImVec4(menuAccentColor[0], menuAccentColor[1], menuAccentColor[2], 0.35f + glowPulse * 0.25f);

        style.Colors[ImGuiCol_Border]                 = accent_dim;
        style.Colors[ImGuiCol_CheckMark]              = accent;
        style.Colors[ImGuiCol_SliderGrab]             = accent;
        style.Colors[ImGuiCol_SliderGrabActive]       = accent_active;
        style.Colors[ImGuiCol_Button]                 = accent_dim;
        style.Colors[ImGuiCol_ButtonHovered]          = accent_hover;
        style.Colors[ImGuiCol_ButtonActive]           = accent_active;
        style.Colors[ImGuiCol_Header]                 = accent_dim;
        style.Colors[ImGuiCol_HeaderHovered]          = ImVec4(accent.x, accent.y, accent.z, 0.6f);
        style.Colors[ImGuiCol_HeaderActive]           = accent;

        // Force Login Overlay Open if Not Logged In
        if (!isLoggedIn || MenDeal)
        {
            // =========================================================
            //  🔐 MODERN AUTH UI (AUTO OPEN & LOCKED UNTIL SUCCESS)
            // =========================================================
            if (!isLoggedIn) {
                ImGui::SetNextWindowSize(ImVec2(410, 260), ImGuiCond_Always);
                ImGui::SetNextWindowPos(ImVec2((io.DisplaySize.x - 410) / 2, (io.DisplaySize.y - 260) / 2), ImGuiCond_Always);
                
                ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1.5f);
                ImGui::PushStyleColor(ImGuiCol_Border, ImVec4(accent.x, accent.y, accent.z, 0.7f + glowPulse * 0.3f));
                
                ImGui::Begin("AuthUI", NULL, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoSavedSettings);
                
                ImVec2 p = ImGui::GetCursorScreenPos();
                ImVec2 size = ImGui::GetWindowSize();
                ImDrawList* drawList = ImGui::GetWindowDrawList();
                
                // Top Visual Gradient Line
                drawList->AddRectFilledMultiColor(
                    ImVec2(p.x, p.y),
                    ImVec2(p.x + size.x, p.y + 4),
                    IM_COL32(accent.x*255, accent.y*255, accent.z*255, 255), 
                    IM_COL32(255, 255, 255, (int)(glowPulse * 200)),  
                    IM_COL32(255, 255, 255, (int)(glowPulse * 200)),
                    IM_COL32(accent.x*255, accent.y*255, accent.z*255, 255)
                );
                
                ImGui::SetCursorPosY(ImGui::GetCursorPosY() + 12);
                
                // Title
                ImGui::SetWindowFontScale(1.2f);
                ImGui::SetCursorPosX((size.x - ImGui::CalcTextSize("STATISTIC VIP AUTHENTICATION").x) / 2);
                ImGui::TextColored(ImVec4(1.0f, 1.0f, 1.0f, 1.0f), "STATISTIC VIP AUTHENTICATION");
                ImGui::SetWindowFontScale(1.0f);
                
                ImGui::Spacing();
                
                // Dynamic Status Display / Crash Countdown Status
                if (shouldCrash) {
                    char crashMsg[128];
                    snprintf(crashMsg, sizeof(crashMsg), "Access Denied! Closing in %.1f s...", crashTimer);
                    ImGui::SetCursorPosX((size.x - ImGui::CalcTextSize(crashMsg).x) / 2);
                    ImGui::TextColored(ImVec4(1.0f, 0.2f, 0.2f, 1.0f), "%s", crashMsg);
                } else {
                    ImGui::SetCursorPosX((size.x - ImGui::CalcTextSize(loginMessage.c_str()).x) / 2);
                    ImGui::TextColored(loginMsgColor, "%s", loginMessage.c_str());
                }
                
                ImGui::Spacing();
                ImGui::Separator();
                ImGui::Spacing();
                
                // Key Input Field
                ImGui::SetCursorPosX(20);
                ImGui::PushItemWidth(size.x - 40);
                ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 6.0f);
                ImGui::InputTextWithHint("##KeyInput", "License Key...", licenseKey, IM_ARRAYSIZE(licenseKey), ImGuiInputTextFlags_Password);
                ImGui::PopStyleVar();
                ImGui::PopItemWidth();
                
                ImGui::Spacing();
                ImGui::Spacing();
                
                // --- BUTTONS ROW ---
                ImGui::SetCursorPosX(20);
                
                // Paste Key Button
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.12f, 0.40f, 0.75f, 0.85f));
                if (ImGui::Button("Paste Key", ImVec2(100, 34))) {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    if (pasteboard.string) {
                        strncpy(licenseKey, pasteboard.string.UTF8String, sizeof(licenseKey) - 1);
                        loginMessage = "Key Pasted! Click Authenticate.";
                        loginMsgColor = ImVec4(0.4f, 0.9f, 0.4f, 1.0f);
                    } else {
                        loginMessage = "Clipboard is empty!";
                        loginMsgColor = ImVec4(1.0f, 0.3f, 0.3f, 1.0f);
                    }
                }
                ImGui::PopStyleColor();
                
                ImGui::SameLine();
                
                // Clear Button
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.75f, 0.18f, 0.18f, 0.7f));
                if (ImGui::Button("Clear", ImVec2(60, 34))) {
                    memset(licenseKey, 0, sizeof(licenseKey));
                    loginMessage = "Cleared!";
                    loginMsgColor = ImVec4(0.8f, 0.8f, 0.8f, 1.0f);
                }
                ImGui::PopStyleColor();
                
                ImGui::SameLine();
                
                // Authenticate Button
                ImGui::PushStyleColor(ImGuiCol_Button, accent);
                ImGui::PushStyleColor(ImGuiCol_ButtonHovered, accent_hover);
                ImGui::PushStyleColor(ImGuiCol_ButtonActive, accent_active);
                
                if (ImGui::Button(isAuthenticating ? "Checking..." : "Authenticate", ImVec2(190, 34))) {
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
                ImGui::PopStyleColor();
                ImGui::PopStyleVar();
            }
            // =========================================================
            //  🎮 MAIN MOD MENU (Accessible ONLY After Valid Login)
            // =========================================================
            else 
            {                
                CGFloat x = (view.bounds.size.width - 480) / 2;
                CGFloat y = (view.bounds.size.height - 380) / 2;
                ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
                ImGui::SetNextWindowSize(ImVec2(480, 380), ImGuiCond_FirstUseEver);
                
                ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1.5f);
                ImGui::PushStyleColor(ImGuiCol_Border, ImVec4(accent.x, accent.y, accent.z, 0.5f));
                
                ImGui::Begin(oxorany(" STATISTIC KING PRO "), &MenDeal, ImGuiWindowFlags_NoCollapse);
                
                ImVec2 p = ImGui::GetCursorScreenPos();
                ImVec2 window_size = ImGui::GetWindowSize();
                
                // Top Header Highlight Line
                ImGui::GetWindowDrawList()->AddRectFilled(
                    ImVec2(p.x - 18, p.y - 12), 
                    ImVec2(p.x + window_size.x - 18, p.y - 10), 
                    ImColor(accent.x, accent.y, accent.z, 0.8f + glowPulse * 0.2f)
                );
                
                ImGui::Spacing();

                if (ImGui::BeginTabBar(oxorany("MainTabs"), ImGuiTabBarFlags_FittingPolicyScroll | ImGuiTabBarFlags_NoTooltip)) 
                {
                    // === TAB 1: ESP ===
                    if (ImGui::BeginTabItem("  ESP  ")) 
                    {
                        ImGui::Spacing();
                        ImGui::Checkbox(oxorany("Enable ESP Master"), &Vars.Enable);
                        ImGui::Separator();
                        ImGui::Spacing();

                        ImGui::Columns(2, "esp_columns", false);
                        ImGui::Checkbox(oxorany("Show Lines"), &Vars.lines);
                        ImGui::Checkbox(oxorany("Show Boxes"), &Vars.Box);
                        ImGui::Checkbox(oxorany("Show Health"), &Vars.Health);
                        ImGui::Checkbox(oxorany("Show Names"), &Vars.Name);
                        
                        ImGui::NextColumn();
                        ImGui::Checkbox(oxorany("Show Skeleton"), &Vars.skeleton);
                        ImGui::Checkbox(oxorany("Show Distance"), &Vars.Distance);
                        ImGui::Checkbox(oxorany("3D Circle"), &Vars.circlepos);
                        ImGui::Checkbox(oxorany("Enemy Outline"), &Vars.Outline);
                        ImGui::Columns(1); 
                        
                        ImGui::Spacing();
                        ImGui::Separator();
                        ImGui::Spacing();

                        ImGui::Checkbox(oxorany("Out of Screen Warning"), &Vars.OOF); 
                        ImGui::Checkbox(oxorany("Total Enemy Count"), &Vars.enemycount);
                        ImGui::EndTabItem();
                    }
                    
                    // === TAB 2: AIMBOT ===
                    if (ImGui::BeginTabItem("  AIMBOT  ")) 
                    {
                        ImGui::Spacing();
                        ImGui::Checkbox(oxorany("Enable Master Aimbot"), &Vars.Aimbot);
                        ImGui::Separator();
                        ImGui::Spacing();

                        ImGui::Columns(2, "aim_columns", false);
                        ImGui::Checkbox(oxorany("Silent Aim"), &SilentAim);
                        ImGui::Checkbox(oxorany("Visible Only"), &Vars.VisibleCheck);
                        
                        ImGui::NextColumn();
                        ImGui::Checkbox(oxorany("Check Wall"), &CheckWall1);
                        ImGui::Checkbox(oxorany("Ignore Knocked"), &Vars.IgnoreKnocked);
                        ImGui::Columns(1);
                        
                        ImGui::Spacing();
                        ImGui::Separator();
                        ImGui::Spacing();

                        ImGui::SetNextItemWidth(220);
                        ImGui::Combo("Trigger Condition", &Vars.AimWhen, Vars.dir, 4);
                        ImGui::Spacing();

                        ImGui::SetNextItemWidth(220);
                        ImGui::Combo("Target Hitbox", &Vars.AimHitbox, Vars.aimHitboxes, 3);
                        ImGui::Spacing();

                        ImGui::SetNextItemWidth(220);
                        ImGui::Combo("Aimbot Mode", &Vars.AimMode, Vars.aimModes, 3);

                        if (Vars.AimMode == 2) {
                            ImGui::Spacing();
                            ImGui::SetNextItemWidth(300);
                            ImGui::SliderFloat(oxorany("FOV Size"), &Vars.AimFov, 0.0f, 360.0f, oxorany("%.0f px Radius"));
                        }
                        ImGui::EndTabItem();
                    }

                    // === TAB 3: SETTINGS & INFO ===
                    if (ImGui::BeginTabItem("  SETTINGS  ")) 
                    {
                        ImGui::Spacing();
                        ImGui::TextDisabled("KEYAUTH DETAILS");
                        ImGui::Separator();
                        ImGui::Spacing();
                        
                        ImGui::Text("API Status:");
                        ImGui::SameLine(120);
                        if (apiConnected) {
                            ImGui::TextColored(ImVec4(0.2f, 1.0f, 0.2f, 1.0f), "Connected Securely");
                        } else {
                            ImGui::TextColored(ImVec4(1.0f, 0.2f, 0.2f, 1.0f), "Disconnected");
                        }

                        ImGui::Text("License Key:");
                        ImGui::SameLine(120);
                        
                        // FIXED MASKED KEY DISPLAY (Replaced Unicode bullets with ASCII '*')
                        std::string keyStr = std::string(licenseKey);
                        std::string maskedKey = keyStr;
                        if (keyStr.length() > 8) {
                            maskedKey = keyStr.substr(0, 4) + "********" + keyStr.substr(keyStr.length() - 4);
                        }
                        ImGui::TextColored(accent, "%s", maskedKey.c_str());

                        ImGui::Text("Expiry Date:");
                        ImGui::SameLine(120);
                        ImGui::TextColored(accent, "%s", keyExpiryDate.c_str());

                        ImGui::Spacing();
                        
                        // LOGOUT BUTTON IN SETTINGS
                        ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.85f, 0.25f, 0.25f, 0.7f));
                        if (ImGui::Button("Logout License Key", ImVec2(180, 30))) {
                            [self logoutKey];
                        }
                        ImGui::PopStyleColor();

                        ImGui::Spacing();
                        ImGui::Spacing();
                        ImGui::TextDisabled("UI CUSTOMIZATION");
                        ImGui::Separator();
                        ImGui::Spacing();
                        
                        ImGui::SetNextItemWidth(220);
                        ImGui::ColorEdit3("Accent Color", menuAccentColor, ImGuiColorEditFlags_NoInputs);
                        
                        ImGui::Spacing();
                        ImGui::Spacing();
                        ImGui::TextDisabled("GAME FIXES");
                        ImGui::Separator();
                        ImGui::Spacing();

                        if (ImGui::Button(oxorany("Execute Fix Login"), ImVec2(160, 32))) {
                            self.view.hidden = YES; 
                            MenDeal = false; 
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fixLoginTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                self.view.hidden = NO; 
                                MenDeal = true; 
                            });
                        }
                        ImGui::SameLine();
                        ImGui::SetNextItemWidth(160);
                        ImGui::SliderFloat(oxorany("##fixlogin"), &fixLoginTimeout, 40.0f, 80.0f, oxorany("Timeout: %.0f s"));
                        
                        ImGui::EndTabItem();
                    }
                    
                    ImGui::EndTabBar();
                }
                ImGui::End();
                ImGui::PopStyleColor();
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
