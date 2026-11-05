import SwiftUI

public struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings & Safety")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Configure cleanup safeguards, disk inspection preferences, and learn about the open-source architecture.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.top, 24)
                
                // Safety Safeguards
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Cleanup Safeguards")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Button("Relaunch Setup Assistant") {
                            viewModel.relaunchOnboarding()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(red: 0.98, green: 0.25, blue: 0.65))
                    }
                    
                    Toggle(isOn: $viewModel.moveToTrashOnly) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Move removed files to Trash (Recommended)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                            Text("Provides a safe recovery net so you can restore any files if needed.")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: viewModel.moveToTrashOnly) { _, val in
                        UserDefaults.standard.set(val, forKey: "moveToTrashOnly")
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Built-in Whitelist Protection")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                            Text("Strictly prohibits scanning or deleting ~/.ssh, Keychains, Photos library, iCloud files, and macOS system binaries.")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        Spacer()
                        Text("Active (Protected)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.20, green: 0.85, blue: 0.55))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.20, green: 0.85, blue: 0.55).opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(20)
                .liquidGlass(cornerRadius: 18)
                
                // Full Disk Access & Zero Developer Account Cost Note
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 0.95))
                        Text("Zero Paid Account Required & Full Disk Access")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    Text("LiquidClean is 100% free and open-source. Because it does not require a paid $99/year Apple Developer membership, it uses standard ad-hoc local code signing (`codesign -s -`). To allow scanning protected system caches and user trash, you can optionally grant Full Disk Access in **System Settings → Privacy & Security → Full Disk Access**.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineSpacing(3)
                    
                    Button("Open Privacy Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 0.95))
                }
                .padding(20)
                .liquidGlass(cornerRadius: 18, tintColor: Color(red: 0.0, green: 0.85, blue: 0.95))
                
                // About LiquidClean
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(red: 0.98, green: 0.25, blue: 0.65), Color(red: 0.35, green: 0.70, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)
                            Image(systemName: "drop.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LiquidClean for macOS")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Version 1.0.0 • Free & Open Source (MIT License)")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    
                    Text("Designed with native Swift and SwiftUI, bringing CleanMyMac's gorgeous fluid liquid glass aesthetics and essential maintenance tools to the open-source community.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(20)
                .liquidGlass(cornerRadius: 18)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
    }
}
