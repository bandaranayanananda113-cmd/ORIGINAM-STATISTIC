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

// 🔴 USER CUSTOMIZABLE THEME COLOR (Default: Professional Blue)
static float menuAccentColor[3] = { 0.16f, 0.56f, 0.96f }; 

// --- LOGIN STATE VARIABLES ---
static bool isLoggedIn = false;
static bool isAuthenticating = false;
static char licenseKey[128] = "";
static std::string loginMessage = "Please authenticate your license key.";
static ImVec4 loginMsgColor = ImVec4(0.7f, 0.7f, 0.7f, 1.0f);
static std::string keyExpiryDate = "Pending...";
static bool apiConnected = false;

#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale

@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
- (void)authenticateKey:(NSString *)key;
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

    // === PROFESSIONAL FLAT DARK THEME SETUP ===
    ImGuiStyle& style = ImGui::GetStyle();
    style.Alpha = 1.0f;
    style.WindowRounding = 8.0f;     
    style.FrameRounding = 4.0f;
    style.ChildRounding = 6.0f;
    style.PopupRounding = 6.0f;
    style.ScrollbarRounding = 6.0f;
    style.GrabRounding = 4.0f;
    style.TabRounding = 4.0f;
    style.WindowBorderSize = 1.0f;
    style.FrameBorderSize = 1.0f;    
    style.WindowPadding = ImVec2(16.0f, 16.0f);
    style.ItemSpacing = ImVec2(10.0f, 12.0f);
    style.ItemInnerSpacing = ImVec2(8.0f, 8.0f);
    
    ImVec4* colors = style.Colors;
    colors[ImGuiCol_Text]                   = ImVec4(0.92f, 0.92f, 0.94f, 1.00f);
    colors[ImGuiCol_TextDisabled]           = ImVec4(0.50f, 0.50f, 0.50f, 1.00f);
    colors[ImGuiCol_WindowBg]               = ImVec4(0.10f, 0.10f, 0.11f, 0.98f);
    colors[ImGuiCol_ChildBg]                = ImVec4(0.13f, 0.13f, 0.14f, 1.00f);
    colors[ImGuiCol_PopupBg]                = ImVec4(0.08f, 0.08f, 0.08f, 0.98f);
    colors[ImGuiCol_FrameBg]                = ImVec4(0.16f, 0.16f, 0.17f, 1.00f);
    colors[ImGuiCol_FrameBgHovered]         = ImVec4(0.20f, 0.20f, 0.22f, 1.00f);
    colors[ImGuiCol_TitleBg]                = ImVec4(0.12f, 0.12f, 0.13f, 1.00f);
    colors[ImGuiCol_TitleBgCollapsed]       = ImVec4(0.00f, 0.00f, 0.00f, 0.51f);
    colors[ImGuiCol_MenuBarBg]              = ImVec4(0.14f, 0.14f, 0.14f, 1.00f);
    colors[ImGuiCol_ScrollbarBg]            = ImVec4(0.02f, 0.02f, 0.02f, 0.53f);
    colors[ImGuiCol_ScrollbarGrab]          = ImVec4(0.31f, 0.31f, 0.31f, 1.00f);
    colors[ImGuiCol_Separator]              = ImVec4(0.20f, 0.20f, 0.22f, 1.00f);

    ImFont* font = io.Fonts->AddFontFromMemoryTTF(sansbold, sizeof(sansbold), 15.0f, NULL, io.Fonts->GetGlyphRangesCyrillic());
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

    Hook(0x58B3258 , BLAGCMCGEJG1, old_BLAGCMCGEJG1);
}

// --- NATIVE KEYAUTH API CONNECTION LOGIC ---
- (void)authenticateKey:(NSString *)key {
    NSString *name = @"STATISTIC PRO";
    NSString *ownerid = @"wFY9t1Imun";
    NSString *version = @"1.0";
    
    // 1. Initializing KeyAuth Session
    NSString *initUrlStr = [NSString stringWithFormat:@"https://keyauth.win/api/1.2/?type=init&ver=%@&name=%@&ownerid=%@", version, [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], ownerid];
    
    NSMutableURLRequest *initReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:initUrlStr]];
    initReq.HTTPMethod = @"GET";
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:initReq completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (err || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                loginMessage = "Server Connection Failed!";
                loginMsgColor = ImVec4(1.0f, 0.2f, 0.2f, 1.0f);
                isAuthenticating = false;
            });
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([json[@"success"] boolValue]) {
            NSString *sessionId = json[@"sessionid"];
            NSString *hwid = [[[UIDevice currentDevice] identifierForVendor] UUIDString]; // iOS HWID
            
            // 2. License Verification
            NSString *licUrlStr = [NSString stringWithFormat:@"https://keyauth.win/api/1.2/?type=license&key=%@&hwid=%@&sessionid=%@&name=%@&ownerid=%@", key, hwid, sessionId, [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], ownerid];
            
            NSMutableURLRequest *licReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:licUrlStr]];
            licReq.HTTPMethod = @"GET";
            
            [[[NSURLSession sharedSession] dataTaskWithRequest:licReq completionHandler:^(NSData *licData, NSURLResponse *licRes, NSError *licErr) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    isAuthenticating = false;
                    if (licErr || !licData) {
                        loginMessage = "API Error, Try again!";
                        loginMsgColor = ImVec4(1.0f, 0.2f, 0.2f, 1.0f);
                        return;
                    }
                    
                    NSDictionary *licJson = [NSJSONSerialization JSONObjectWithData:licData options:0 error:nil];
                    if ([licJson[@"success"] boolValue]) {
                        isLoggedIn = true;
                        apiConnected = true;
                        loginMessage = "Login Successful!";
                        loginMsgColor = ImVec4(0.2f, 1.0f, 0.2f, 1.0f);
                        
                        // Parse Expiry Date
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
                        if ([msg containsString:@"invalid"]) {
                            loginMessage = "Invalid Key!";
                        } else if ([msg containsString:@"hwid"]) {
                            loginMessage = "Reset Your Key (HWID Mismatch)";
                        } else if ([msg containsString:@"used"]) {
                            loginMessage = "Key Already Used!";
                        } else {
                            loginMessage = std::string([msg UTF8String]);
                        }
                        loginMsgColor = ImVec4(1.0f, 0.2f, 0.2f, 1.0f);
                    }
                });
            }] resume];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                loginMessage = "App Initialization Failed!";
                loginMsgColor = ImVec4(1.0f, 0.2f, 0.2f, 1.0f);
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

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.nativeScale ?: UIScreen.mainScreen.nativeScale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1.0f / float(view.preferredFramesPerSecond ?: 60);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        
    [self.view setUserInteractionEnabled:MenDeal];

    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui Main View"];

        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();
        
        // --- APPLY DYNAMIC ACCENT COLOR GLOBALLY ---
        ImGuiStyle& style = ImGui::GetStyle();
        ImVec4 accent = ImVec4(menuAccentColor[0], menuAccentColor[1], menuAccentColor[2], 1.0f);
        ImVec4 accent_hover = ImVec4(menuAccentColor[0] * 1.15f, menuAccentColor[1] * 1.15f, menuAccentColor[2] * 1.15f, 1.0f);
        ImVec4 accent_active = ImVec4(menuAccentColor[0] * 0.85f, menuAccentColor[1] * 0.85f, menuAccentColor[2] * 0.85f, 1.0f);
        ImVec4 accent_dim = ImVec4(menuAccentColor[0], menuAccentColor[1], menuAccentColor[2], 0.4f);

        style.Colors[ImGuiCol_Border]                 = accent_dim;
        style.Colors[ImGuiCol_BorderShadow]           = ImVec4(0.0f, 0.0f, 0.0f, 0.0f);
        style.Colors[ImGuiCol_TitleBgActive]          = ImVec4(0.12f, 0.12f, 0.13f, 1.00f);
        style.Colors[ImGuiCol_CheckMark]              = accent;
        style.Colors[ImGuiCol_SliderGrab]             = accent;
        style.Colors[ImGuiCol_SliderGrabActive]       = accent_active;
        style.Colors[ImGuiCol_Button]                 = accent_dim;
        style.Colors[ImGuiCol_ButtonHovered]          = accent_hover;
        style.Colors[ImGuiCol_ButtonActive]           = accent_active;
        style.Colors[ImGuiCol_Header]                 = accent_dim;
        style.Colors[ImGuiCol_HeaderHovered]          = ImVec4(accent.x, accent.y, accent.z, 0.6f);
        style.Colors[ImGuiCol_HeaderActive]           = accent;
        style.Colors[ImGuiCol_Tab]                    = ImVec4(0.15f, 0.15f, 0.16f, 1.00f);
        style.Colors[ImGuiCol_TabHovered]             = ImVec4(accent.x, accent.y, accent.z, 0.7f);
        style.Colors[ImGuiCol_TabActive]              = accent;

        if (MenDeal)
        {
            // ==========================================
            //           LOGIN INTERFACE
            // ==========================================
            if (!isLoggedIn) {
                ImGui::SetNextWindowSize(ImVec2(400, 260), ImGuiCond_Always);
                ImGui::SetNextWindowPos(ImVec2((io.DisplaySize.x - 400) / 2, (io.DisplaySize.y - 260) / 2), ImGuiCond_Always);
                
                ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding, 12.0f);
                ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
                
                ImGui::Begin("Login", NULL, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoScrollbar);
                
                ImVec2 p = ImGui::GetCursorScreenPos();
                ImVec2 size = ImGui::GetWindowSize();
                ImDrawList* drawList = ImGui::GetWindowDrawList();
                
                // 3D Premium Gradient Header Bar
                drawList->AddRectFilledMultiColor(
                    ImVec2(p.x - 16, p.y - 16),
                    ImVec2(p.x + size.x - 16, p.y + 6),
                    IM_COL32(accent.x*255, accent.y*255, accent.z*255, 255), 
                    IM_COL32(100, 40, 245, 255),  
                    IM_COL32(50, 20, 200, 255),
                    IM_COL32(accent.x*200, accent.y*200, accent.z*200, 255)
                );
                
                ImGui::SetCursorPosY(ImGui::GetCursorPosY() + 15);
                
                // Centered App Name
                ImGui::SetCursorPosX((size.x - ImGui::CalcTextSize("STATISTIC PRO").x) / 2);
                ImGui::TextColored(ImVec4(1, 1, 1, 1), "STATISTIC PRO");
                ImGui::Spacing();
                
                // Dynamic Status Message
                ImGui::SetCursorPosX((size.x - ImGui::CalcTextSize(loginMessage.c_str()).x) / 2);
                ImGui::TextColored(loginMsgColor, "%s", loginMessage.c_str());
                
                ImGui::Spacing();
                ImGui::Spacing();
                
                // License Key Input
                ImGui::SetCursorPosX(30);
                ImGui::PushItemWidth(size.x - 60);
                ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 6.0f);
                ImGui::PushStyleVar(ImGuiStyleVar_FramePadding, ImVec2(10, 10));
                ImGui::InputTextWithHint("##KeyInput", "Paste your License Key here...", licenseKey, IM_ARRAYSIZE(licenseKey), ImGuiInputTextFlags_Password);
                ImGui::PopStyleVar(2);
                ImGui::PopItemWidth();
                
                ImGui::Spacing();
                ImGui::Spacing();
                ImGui::Spacing();
                
                // Buttons Centered
                ImGui::SetCursorPosX((size.x - 260) / 2);
                ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 8.0f);
                
                if (ImGui::Button("Paste Key", ImVec2(120, 40))) {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    if (pasteboard.string) {
                        strncpy(licenseKey, pasteboard.string.UTF8String, sizeof(licenseKey) - 1);
                    }
                }
                
                ImGui::SameLine(0, 20);
                
                if (ImGui::Button(isAuthenticating ? "Loading..." : "Login", ImVec2(120, 40))) {
                    if (strlen(licenseKey) > 0 && !isAuthenticating) {
                        isAuthenticating = true;
                        loginMessage = "Connecting to Secure Server...";
                        loginMsgColor = ImVec4(1.0f, 0.8f, 0.2f, 1.0f);
                        [self authenticateKey:[NSString stringWithUTF8String:licenseKey]];
                    } else if (strlen(licenseKey) == 0) {
                        loginMessage = "Please paste a valid key first!";
                        loginMsgColor = ImVec4(1.0f, 0.3f, 0.3f, 1.0f);
                    }
                }
                
                ImGui::PopStyleVar();
                ImGui::End();
                ImGui::PopStyleVar(2);
            }
            // ==========================================
            //           MAIN MENU INTERFACE
            // ==========================================
            else 
            {                
                CGFloat x = (view.bounds.size.width - 450) / 2;
                CGFloat y = (view.bounds.size.height - 350) / 2;
                ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
                ImGui::SetNextWindowSize(ImVec2(450, 350), ImGuiCond_FirstUseEver);
                
                ImGui::Begin(oxorany("Statistics King PRO"), &MenDeal, ImGuiWindowFlags_NoCollapse);
                
                ImVec2 p = ImGui::GetCursorScreenPos();
                ImVec2 window_size = ImGui::GetWindowSize();
                ImGui::GetWindowDrawList()->AddRectFilled(ImVec2(p.x - 16, p.y - 16), ImVec2(p.x + window_size.x - 16, p.y - 13), ImColor(accent));
                
                ImGui::Spacing();

                if (ImGui::BeginTabBar(oxorany("MainTabs"), ImGuiTabBarFlags_FittingPolicyScroll | ImGuiTabBarFlags_NoTooltip)) 
                {
                    // === TAB 1: ESP ===
                    if (ImGui::BeginTabItem("ESP")) 
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
                    if (ImGui::BeginTabItem("Aimbot")) 
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

                        ImGui::SetNextItemWidth(200);
                        ImGui::Combo("Trigger Condition", &Vars.AimWhen, Vars.dir, 4);

                        ImGui::SetNextItemWidth(200);
                        ImGui::Combo("Target Hitbox", &Vars.AimHitbox, Vars.aimHitboxes, 3);

                        ImGui::SetNextItemWidth(200);
                        ImGui::Combo("Aimbot Mode", &Vars.AimMode, Vars.aimModes, 3);

                        if (Vars.AimMode == 2) {
                            ImGui::Spacing();
                            ImGui::SetNextItemWidth(300);
                            ImGui::SliderFloat(oxorany("FOV Size"), &Vars.AimFov, 0.0f, 360.0f, oxorany("%.0f px Radius"));
                        }
                        ImGui::EndTabItem();
                    }

                    // === TAB 3: SETTINGS & INFO ===
                    if (ImGui::BeginTabItem("Settings")) 
                    {
                        ImGui::Spacing();
                        ImGui::TextDisabled("KEYAUTH DETAILS");
                        ImGui::Separator();
                        ImGui::Spacing();
                        
                        ImGui::Text("API Status:");
                        ImGui::SameLine();
                        if (apiConnected) {
                            ImGui::TextColored(ImVec4(0.2f, 1.0f, 0.2f, 1.0f), "Connected");
                        } else {
                            ImGui::TextColored(ImVec4(1.0f, 0.2f, 0.2f, 1.0f), "Disconnected");
                        }

                        ImGui::Text("License Key:");
                        ImGui::SameLine();
                        std::string maskedKey = std::string(licenseKey);
                        if (maskedKey.length() > 8) {
                            maskedKey = maskedKey.substr(0, 4) + "...." + maskedKey.substr(maskedKey.length() - 4);
                        }
                        ImGui::TextColored(accent, "%s", maskedKey.c_str());

                        ImGui::Text("Expiry Date:");
                        ImGui::SameLine();
                        ImGui::TextColored(accent, "%s", keyExpiryDate.c_str());

                        ImGui::Spacing();
                        ImGui::Spacing();
                        ImGui::TextDisabled("UI CUSTOMIZATION");
                        ImGui::Separator();
                        ImGui::Spacing();
                        
                        ImGui::SetNextItemWidth(200);
                        ImGui::ColorEdit3("Menu Theme Color", menuAccentColor, ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_NoLabel);
                        ImGui::SameLine();
                        ImGui::Text("Menu Accent Color");
                        
                        ImGui::Spacing();
                        ImGui::Spacing();
                        ImGui::TextDisabled("GAME FIXES");
                        ImGui::Separator();
                        ImGui::Spacing();

                        if (ImGui::Button(oxorany("Execute Fix Login"), ImVec2(150, 30))) {
                            self.view.hidden = YES; 
                            MenDeal = false; 
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fixLoginTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                self.view.hidden = NO; 
                                MenDeal = true; 
                            });
                        }
                        ImGui::SameLine();
                        ImGui::SetNextItemWidth(150);
                        ImGui::SliderFloat(oxorany("##fixlogin"), &fixLoginTimeout, 40.0f, 80.0f, oxorany("Timeout: %.0f s"));
                        
                        ImGui::EndTabItem();
                    }
                    
                    ImGui::EndTabBar();
                }
                ImGui::End();
            }
        }
        
        // --- Game Drawing & Logic Calls (UNTOUCHED) ---
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
