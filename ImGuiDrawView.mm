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
static bool MenDeal = true; 

// MENU COLOR & TRANSPARENCY
static float menuAccentColor[4] = { 0.68f, 0.28f, 0.98f, 1.0f }; 
static float menuAlpha = 0.85f;
static int currentTab = 0; // 0: Aimbot, 1: ESP, 2: Settings

// STREAM PROOF CONTROL
static bool streamProofEnabled = false;

// CUSTOM COLORS
static float espLineColor[4] = { 0.95f, 0.25f, 0.25f, 1.0f };
static float espBoxColor[4]  = { 0.25f, 0.95f, 0.35f, 1.0f };
static float fovCircleColor[4] = { 0.25f, 0.75f, 1.0f, 0.85f };

// LOGIN STATE
static bool isLoggedIn = false;
static bool isAuthenticating = false;
static char licenseKey[128] = "";
static std::string loginMessage = "Please Enter License Key";
static ImVec4 loginMsgColor = ImVec4(0.85f, 0.85f, 0.85f, 1.0f);
static std::string keyExpiryDate = "Pending...";
static bool apiConnected = false;

// SAKURA PETALS ANIMATION STRUCT
struct SakuraPetal {
    float x, y;
    float speedY, speedX;
    float size;
    float rotation;
    float rotSpeed;
    float alpha;
};
static std::vector<SakuraPetal> sakuraPetals;
static bool sakuraInitialized = false;

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

    // HIGH DPI SHARP FONT & CLEAN UI SETUP
    ImGuiStyle& style = ImGui::GetStyle();
    style.Alpha = 1.0f;
    style.WindowRounding = 10.0f;     
    style.FrameRounding = 6.0f;
    style.ChildRounding = 8.0f;
    style.PopupRounding = 8.0f;
    style.ScrollbarRounding = 8.0f;
    style.GrabRounding = 6.0f;
    style.TabRounding = 6.0f;
    style.WindowBorderSize = 1.0f;
    style.FrameBorderSize = 1.0f;    
    style.WindowPadding = ImVec2(12.0f, 12.0f);
    style.ItemSpacing = ImVec2(8.0f, 8.0f);
    style.AntiAliasedLines = true;
    style.AntiAliasedFill = true;
    
    ImVec4* colors = style.Colors;
    colors[ImGuiCol_Text]                   = ImVec4(0.98f, 0.98f, 0.98f, 1.00f);
    colors[ImGuiCol_TextDisabled]           = ImVec4(0.55f, 0.55f, 0.60f, 1.00f);
    colors[ImGuiCol_WindowBg]               = ImVec4(0.08f, 0.07f, 0.11f, menuAlpha);
    colors[ImGuiCol_ChildBg]                = ImVec4(0.12f, 0.10f, 0.16f, 0.65f);
    colors[ImGuiCol_PopupBg]                = ImVec4(0.08f, 0.07f, 0.12f, 0.98f);
    colors[ImGuiCol_FrameBg]                = ImVec4(0.15f, 0.13f, 0.22f, 1.00f);
    colors[ImGuiCol_FrameBgHovered]         = ImVec4(0.22f, 0.18f, 0.32f, 1.00f);
    colors[ImGuiCol_TitleBg]                = ImVec4(0.08f, 0.07f, 0.11f, 1.00f);
    colors[ImGuiCol_TitleBgActive]          = ImVec4(0.08f, 0.07f, 0.11f, 1.00f);
    colors[ImGuiCol_ScrollbarBg]            = ImVec4(0.03f, 0.02f, 0.05f, 0.30f);
    colors[ImGuiCol_ScrollbarGrab]          = ImVec4(0.35f, 0.25f, 0.48f, 1.00f);
    colors[ImGuiCol_Separator]              = ImVec4(0.22f, 0.18f, 0.32f, 1.00f);

    // Font crisp rendering setup
    ImFontConfig font_cfg;
    font_cfg.SizePixels = 15.0f;
    font_cfg.OversampleH = 3;
    font_cfg.OversampleV = 3;
    font_cfg.PixelSnapH = true;

    ImFont* font = io.Fonts->AddFontFromMemoryTTF(sansbold, sizeof(sansbold), 15.0f, &font_cfg, io.Fonts->GetGlyphRangesCyrillic());
    verdana_smol = io.Fonts->AddFontFromMemoryTTF(verdana, sizeof(verdana), 30, NULL, io.Fonts->GetGlyphRangesCyrillic());
    pixel_big = io.Fonts->AddFontFromMemoryTTF((void*)smallestpixel, sizeof(smallestpixel), 64, NULL, io.Fonts->GetGlyphRangesCyrillic());
    pixel_smol = io.Fonts->AddFontFromMemoryTTF((void*)smallestpixel, sizeof(smallestpixel), 16, NULL, io.Fonts->GetGlyphRangesCyrillic());
    
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
    self.mtkView.contentScaleFactor = [UIScreen mainScreen].nativeScale;
    
    // Enable Touch Input immediately on Startup for Login Key Input
    self.view.userInteractionEnabled = YES;
    self.view.hidden = NO;

    Hook(0x58B3258 , BLAGCMCGEJG1, old_BLAGCMCGEJG1);

    // Auto Login Check
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedLicenseKey"];
    if (savedKey && savedKey.length > 0) {
        strncpy(licenseKey, [savedKey UTF8String], sizeof(licenseKey) - 1);
        isAuthenticating = true;
        loginMessage = "Authenticating Saved Key...";
        loginMsgColor = ImVec4(0.3f, 0.8f, 1.0f, 1.0f);
        [self authenticateKey:savedKey];
    }
}

- (void)logoutKey {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SavedLicenseKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    isLoggedIn = false;
    apiConnected = false;
    memset(licenseKey, 0, sizeof(licenseKey));
    loginMessage = "Logged Out. Please enter a valid key.";
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
                loginMessage = "Server Connection Failed!";
                loginMsgColor = ImVec4(1.0f, 0.3f, 0.3f, 1.0f);
                isAuthenticating = false;
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
                        loginMessage = "API Error! Please try again.";
                        loginMsgColor = ImVec4(1.0f, 0.3f, 0.3f, 1.0f);
                        return;
                    }
                    
                    NSDictionary *licJson = [NSJSONSerialization JSONObjectWithData:licData options:0 error:nil];
                    if ([licJson[@"success"] boolValue]) {
                        isLoggedIn = true;
                        apiConnected = true;
                        
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedLicenseKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                        loginMessage = "Login Successful!";
                        loginMsgColor = ImVec4(0.3f, 1.0f, 0.4f, 1.0f);
                        
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
                        
                        loginMsgColor = ImVec4(1.0f, 0.3f, 0.3f, 1.0f);
                    }
                });
            }] resume];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                loginMessage = "App Init Failed!";
                loginMsgColor = ImVec4(1.0f, 0.3f, 0.3f, 1.0f);
                isAuthenticating = false;
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

#pragma mark - INSIDE-WINDOW SAKURA ANIMATION

- (void)renderInsideWindowSakura:(ImDrawList*)drawList windowPos:(ImVec2)winPos windowSize:(ImVec2)winSize {
    if (!sakuraInitialized) {
        sakuraPetals.resize(30);
        for (auto& p : sakuraPetals) {
            p.x = (float)(rand() % (int)winSize.x);
            p.y = (float)(rand() % (int)winSize.y);
            p.speedY = 0.4f + (rand() % 100) / 100.0f;
            p.speedX = -0.2f + (rand() % 100) / 200.0f;
            p.size = 4.0f + (rand() % 6);
            p.rotation = (rand() % 360) * 3.14159f / 180.0f;
            p.rotSpeed = 0.01f + (rand() % 50) / 1000.0f;
            p.alpha = 0.35f + (rand() % 40) / 100.0f;
        }
        sakuraInitialized = true;
    }

    for (auto& p : sakuraPetals) {
        p.y += p.speedY;
        p.x += p.speedX;
        p.rotation += p.rotSpeed;

        if (p.y > winSize.y) {
            p.y = 0;
            p.x = (float)(rand() % (int)winSize.x);
        }
        if (p.x < 0) p.x = winSize.x;
        if (p.x > winSize.x) p.x = 0;

        ImVec2 absPos = ImVec2(winPos.x + p.x, winPos.y + p.y);
        ImVec2 radius = ImVec2(p.size * 0.7f, p.size * 1.3f);
        
        ImU32 petalColor = IM_COL32(255, 182, 193, (int)(p.alpha * 255));
        drawList->AddEllipseFilled(absPos, radius, petalColor, p.rotation, 10);
    }
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.nativeScale ?: UIScreen.mainScreen.nativeScale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1.0f / float(view.preferredFramesPerSecond ?: 60);

    // FIXED TOUCH CONTROLLER - Touch works on Login & Menu Toggle
    self.view.userInteractionEnabled = (!isLoggedIn ? YES : MenDeal);

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
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
        style.Colors[ImGuiCol_Button]                 = ImVec4(0.15f, 0.13f, 0.22f, 1.0f);
        style.Colors[ImGuiCol_ButtonHovered]          = accent_dim;
        style.Colors[ImGuiCol_ButtonActive]           = accent;

        if (!isLoggedIn || MenDeal)
        {
            // =========================================================
            //  🔐 KEY AUTH UI (STARTUP KEY SYSTEM)
            // =========================================================
            if (!isLoggedIn) {
                ImGui::SetNextWindowSize(ImVec2(420, 240), ImGuiCond_Always);
                ImGui::SetNextWindowPos(ImVec2((io.DisplaySize.x - 420) / 2, (io.DisplaySize.y - 240) / 2), ImGuiCond_Always);
                
                ImGui::Begin("AuthUI", NULL, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoScrollbar);
                
                // Sakura animation rendered strictly inside KeyAuth Window Background
                ImVec2 wPos = ImGui::GetWindowPos();
                ImVec2 wSize = ImGui::GetWindowSize();
                [self renderInsideWindowSakura:ImGui::GetWindowDrawList() windowPos:wPos windowSize:wSize];

                ImGui::SetCursorPosY(16);
                ImGui::SetCursorPosX((wSize.x - ImGui::CalcTextSize("STATISTICS KING VIP").x) / 2);
                ImGui::TextColored(accent, "STATISTICS KING VIP");
                
                ImGui::SetCursorPosX((wSize.x - ImGui::CalcTextSize("AUTHENTICATION SYSTEM").x) / 2);
                ImGui::TextDisabled("AUTHENTICATION SYSTEM");
                
                ImGui::Spacing();
                
                ImGui::SetCursorPosX((wSize.x - ImGui::CalcTextSize(loginMessage.c_str()).x) / 2);
                ImGui::TextColored(loginMsgColor, "%s", loginMessage.c_str());
                
                ImGui::Spacing();
                ImGui::Separator();
                ImGui::Spacing();
                
                ImGui::Text(" License Key:");
                ImGui::SetNextItemWidth(wSize.x - 110);
                ImGui::InputTextWithHint("##KeyInput", "Paste or Enter License Key...", licenseKey, IM_ARRAYSIZE(licenseKey), ImGuiInputTextFlags_Password);
                
                ImGui::SameLine();
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.7f, 0.2f, 0.2f, 0.8f));
                if (ImGui::Button("Clear", ImVec2(60, 24))) {
                    memset(licenseKey, 0, sizeof(licenseKey));
                    loginMessage = "Key Cleared!";
                    loginMsgColor = ImVec4(0.8f, 0.8f, 0.8f, 1.0f);
                }
                ImGui::PopStyleColor();
                
                ImGui::Spacing();
                ImGui::Spacing();
                
                ImGui::SetCursorPosX(15);
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.20f, 0.45f, 0.85f, 0.85f));
                if (ImGui::Button("Paste Key", ImVec2(170, 34))) {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    if (pasteboard.string) {
                        strncpy(licenseKey, pasteboard.string.UTF8String, sizeof(licenseKey) - 1);
                        loginMessage = "Key Pasted! Click Login.";
                        loginMsgColor = ImVec4(0.3f, 1.0f, 0.4f, 1.0f);
                    }
                }
                ImGui::PopStyleColor();
                
                ImGui::SameLine();
                
                ImGui::PushStyleColor(ImGuiCol_Button, accent);
                ImGui::PushStyleColor(ImGuiCol_ButtonHovered, accent_hover);
                if (ImGui::Button(isAuthenticating ? "Checking..." : "Login to System", ImVec2(200, 34))) {
                    if (!isAuthenticating) {
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
                ImGui::PopStyleColor(2);
                
                ImGui::End();
            }
            // =========================================================
            //  🎮 MAIN MOD MENU (3 TABS: AIMBOT, ESP, SETTINGS)
            // =========================================================
            else 
            {                
                ImGui::SetNextWindowSize(ImVec2(580, 350), ImGuiCond_FirstUseEver);
                ImGui::SetNextWindowPos(ImVec2((io.DisplaySize.x - 580) / 2, (io.DisplaySize.y - 350) / 2), ImGuiCond_FirstUseEver);
                
                ImGui::Begin("STATISTICS KING", &MenDeal, ImGuiWindowFlags_NoCollapse);
                
                ImVec2 wPos = ImGui::GetWindowPos();
                ImVec2 wSize = ImGui::GetWindowSize();
                
                // Sakura animation inside Main Window background
                [self renderInsideWindowSakura:ImGui::GetWindowDrawList() windowPos:wPos windowSize:wSize];

                // Left Navigation Sidebar
                ImGui::BeginChild("Sidebar", ImVec2(140, 0), true);
                
                ImGui::SetCursorPosY(12);
                ImGui::TextColored(accent, " STATISTICS KING");
                ImGui::Separator();
                ImGui::Spacing();
                
                #define DRAW_TAB_BTN(name, index) \
                    if (currentTab == index) { \
                        ImGui::PushStyleColor(ImGuiCol_Button, accent); \
                    } else { \
                        ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.12f, 0.10f, 0.16f, 0.6f)); \
                    } \
                    if (ImGui::Button(name, ImVec2(120, 34))) { currentTab = index; } \
                    ImGui::PopStyleColor(); \
                    ImGui::Spacing();

                DRAW_TAB_BTN("  Aimbot", 0);
                DRAW_TAB_BTN("  Visuals (ESP)", 1);
                DRAW_TAB_BTN("  Settings", 2);
                
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
                    
                    ImGui::SetNextItemWidth(200);
                    ImGui::Combo("Aimbot Config", &Vars.AimWhen, Vars.dir, 4);
                    
                    ImGui::Checkbox("Silent Aim", &SilentAim);
                    
                    ImGui::SetNextItemWidth(200);
                    ImGui::Combo("Aiming Method", &Vars.AimMode, Vars.aimModes, 3);
                    
                    ImGui::Checkbox("Show FOV Circle", &Vars.isAimFov);
                    ImGui::SameLine(200);
                    ImGui::ColorEdit4("##FovColor", fovCircleColor, ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_AlphaBar);
                    
                    ImGui::Checkbox("Ignore Knocked", &Vars.IgnoreKnocked);
                    ImGui::Checkbox("Check Wall", &CheckWall1);
                    
                    ImGui::SetNextItemWidth(200);
                    ImGui::Combo("Hitbox Target", &Vars.AimHitbox, Vars.aimHitboxes, 3);
                    
                    ImGui::SetNextItemWidth(240);
                    ImGui::SliderFloat("FOV Radius", &Vars.AimFov, 0.0f, 360.0f, "%.1f Deg");
                }
                
                // --- TAB 1: VISUALS (ESP + MISC MERGED) ---
                else if (currentTab == 1) {
                    ImGui::TextColored(accent, "VISUALS & ESP FUNCTIONS");
                    ImGui::Separator();
                    ImGui::Spacing();

                    ImGui::Checkbox("Enemy ESP", &Vars.Enable);
                    
                    ImGui::Checkbox("Line", &Vars.lines);
                    ImGui::SameLine(180);
                    ImGui::ColorEdit4("##LineColor", espLineColor, ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_AlphaBar);
                    
                    ImGui::Checkbox("Box", &Vars.Box);
                    ImGui::SameLine(180);
                    ImGui::ColorEdit4("##BoxColor", espBoxColor, ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_AlphaBar);
                    
                    ImGui::Checkbox("Health", &Vars.Health);
                    ImGui::Checkbox("Nickname", &Vars.Name);
                    ImGui::Checkbox("Distance", &Vars.Distance);
                    ImGui::Checkbox("Skeleton", &Vars.skeleton);
                    ImGui::Checkbox("3D Circle", &Vars.circlepos);
                    ImGui::Checkbox("Nearby Enemies Count", &Vars.enemycount);

                    ImGui::Spacing();
                    ImGui::Separator();
                    ImGui::TextDisabled("EXTRA VISUAL UTILITIES");
                    ImGui::Spacing();

                    // MERGED MISC ITEMS HERE
                    ImGui::Checkbox("Out of Screen Warning", &Vars.OOF);
                    ImGui::Checkbox("Enemy Outline", &Vars.Outline);
                }
                
                // --- TAB 2: SETTINGS ---
                else if (currentTab == 2) {
                    ImGui::TextColored(accent, "SYSTEM & THEME SETTINGS");
                    ImGui::Separator();
                    ImGui::Spacing();

                    ImGui::Checkbox("Stream Proof Mode", &streamProofEnabled);
                    ImGui::Spacing();

                    ImGui::Text("API Server:");
                    ImGui::SameLine(130);
                    ImGui::TextColored(apiConnected ? ImVec4(0.3f, 1.0f, 0.4f, 1.0f) : ImVec4(1.0f, 0.3f, 0.3f, 1.0f), apiConnected ? "CONNECTED SECURELY" : "DISCONNECTED");

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
                    
                    ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.75f, 0.18f, 0.18f, 0.8f));
                    if (ImGui::Button("Logout Account", ImVec2(150, 30))) {
                        [self logoutKey];
                    }
                    ImGui::PopStyleColor();

                    ImGui::Spacing();
                    ImGui::Separator();
                    ImGui::Spacing();

                    ImGui::SetNextItemWidth(200);
                    ImGui::ColorEdit4("Menu Accent Color", menuAccentColor, ImGuiColorEditFlags_AlphaBar);
                    
                    ImGui::SetNextItemWidth(200);
                    ImGui::SliderFloat("Menu Transparency", &menuAlpha, 0.20f, 1.00f, "%.2f");

                    ImGui::Spacing();
                    ImGui::Separator();
                    ImGui::Spacing();

                    if (ImGui::Button("Execute Fix Login", ImVec2(150, 28))) {
                        self.view.hidden = YES; 
                        MenDeal = false; 
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fixLoginTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            self.view.hidden = NO; 
                            MenDeal = true; 
                        });
                    }
                    ImGui::SameLine();
                    ImGui::SetNextItemWidth(130);
                    ImGui::SliderFloat("##fixlogin", &fixLoginTimeout, 40.0f, 80.0f, "Timeout: %.0f s");
                }
                
                ImGui::EndChild();
                
                ImGui::End();
            }
        }
        
        // --- Game Logic Render ---
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
