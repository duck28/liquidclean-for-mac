import SwiftUI

public struct OnboardingView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var isPresented: Bool
    
    @State private var currentStep = 0
    @State private var hasFDA = false
    @State private var selectedDeletionMode: Bool = true // true = Trash, false = Direct
    
    public init(viewModel: AppViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
    }
    
    public var body: some View {
        ZStack {
            // Ambient dark blurred backdrop
            Color.black.opacity(0.65)
                .ignoresSafeArea()
            
            // Modal Container
            VStack(spacing: 0) {
                // Top Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { idx in
                        Capsule()
                            .fill(idx <= currentStep ? Color(red: 0.98, green: 0.25, blue: 0.65) : Color.white.opacity(0.15))
                            .frame(height: 4)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                
                // Step Content
                ZStack {
                    switch currentStep {
                    case 0:
                        welcomeStep
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                     removal: .move(edge: .leading).combined(with: .opacity)))
                    case 1:
                        permissionsStep
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                     removal: .move(edge: .leading).combined(with: .opacity)))
                    case 2:
                        deletionModeStep
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                     removal: .move(edge: .leading).combined(with: .opacity)))
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                
                // Bottom Navigation Footer
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    if currentStep < 2 {
                        GlassButton("Continue", icon: "arrow.right") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentStep += 1
                                if currentStep == 1 {
                                    refreshPermissions()
                                }
                            }
                        }
                    } else {
                        GlassButton("Finish Setup & Scan", icon: "sparkles", style: .primary(colors: [Color(red: 0.20, green: 0.85, blue: 0.55), Color(red: 0.10, green: 0.65, blue: 0.50)])) {
                            completeSetup()
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            .frame(width: 580, height: 500)
            .liquidGlass(cornerRadius: 24, tintColor: Color(red: 0.98, green: 0.25, blue: 0.65))
            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
        }
        .onAppear {
            selectedDeletionMode = viewModel.moveToTrashOnly
            refreshPermissions()
        }
    }
    
    // MARK: - Step 1: Welcome
    @ViewBuilder
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.98, green: 0.25, blue: 0.65).opacity(0.5), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "drop.fill")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.25, blue: 0.65), Color(red: 0.35, green: 0.70, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.98, green: 0.25, blue: 0.65).opacity(0.6), radius: 15)
            }
            
            VStack(spacing: 6) {
                Text("Welcome to LiquidClean")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Free, open-source Mac cleaner built with native Swift and fluid liquid glass aesthetics.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                featureBullet(icon: "shield.slash.fill", title: "No Paid Apple Developer Account Needed", desc: "Runs free and open with standard ad-hoc code signing.")
                featureBullet(icon: "eye.slash.fill", title: "100% Private & Local", desc: "Zero telemetry, zero network tracking, and zero ads.")
                featureBullet(icon: "lock.shield.fill", title: "Built-in System Whitelist", desc: "Guarantees keys, system files, and documents are never touched.")
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    // MARK: - Step 2: Permissions
    @ViewBuilder
    private var permissionsStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Image(systemName: "hand.raised.square.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 0.95))
                    .padding(.top, 8)
                
                Text("Permissions & Full Disk Access")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("macOS requires Full Disk Access to allow cleaning system application caches, diagnostic logs, and Time Machine restore points.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }
            
            // Full Disk Access Card
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: hasFDA ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(hasFDA ? Color(red: 0.20, green: 0.85, blue: 0.55) : Color(red: 0.98, green: 0.65, blue: 0.20))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Full Disk Access")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(hasFDA ? "Granted • Full system cleaning unlocked" : "Recommended for deep cache cleaning")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    if hasFDA {
                        Text("Active")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.20, green: 0.85, blue: 0.55))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.20, green: 0.85, blue: 0.55).opacity(0.15))
                            .clipShape(Capsule())
                    } else {
                        Button("Open Settings") {
                            PermissionManager.shared.openFullDiskAccessSettings()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.0, green: 0.85, blue: 0.95).opacity(0.35))
                        .clipShape(Capsule())
                    }
                }
                
                if !hasFDA {
                    HStack {
                        Text("In System Settings, enable LiquidClean under Full Disk Access, then click Check Again.")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.55))
                        
                        Spacer()
                        
                        Button("Check Again") {
                            refreshPermissions()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 0.95))
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Standard User Folder Access Card
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(red: 0.20, green: 0.85, blue: 0.55))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("User Folders Access (Downloads, Caches)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Ready for inspecting large files, downloads, and app leftovers")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
            }
            .padding(14)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            Spacer()
        }
    }
    
    // MARK: - Step 3: Deletion Preference
    @ViewBuilder
    private var deletionModeStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(red: 0.98, green: 0.25, blue: 0.65))
                    .padding(.top, 8)
                
                Text("Select Deletion Strategy")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Choose how LiquidClean should remove junk, logs, and temporary files.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                // Option 1: Move to Trash (Recommended)
                Button {
                    selectedDeletionMode = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: selectedDeletionMode ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(selectedDeletionMode ? Color(red: 0.98, green: 0.25, blue: 0.65) : .white.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("Move to Trash")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text("RECOMMENDED")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(red: 0.20, green: 0.85, blue: 0.55))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(red: 0.20, green: 0.85, blue: 0.55).opacity(0.18))
                                    .clipShape(Capsule())
                            }
                            
                            Text("Safe recovery net. Files are moved to your macOS Trash bin so you can inspect or restore them if ever needed.")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.65))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(selectedDeletionMode ? Color.white.opacity(0.09) : Color.white.opacity(0.03))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(selectedDeletionMode ? Color(red: 0.98, green: 0.25, blue: 0.65).opacity(0.6) : Color.white.opacity(0.08), lineWidth: selectedDeletionMode ? 1.5 : 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                
                // Option 2: Direct Permanent Delete
                Button {
                    selectedDeletionMode = false
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: !selectedDeletionMode ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(!selectedDeletionMode ? Color(red: 0.98, green: 0.25, blue: 0.65) : .white.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("Direct Permanent Deletion")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text("INSTANT RECLAIM")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(red: 0.98, green: 0.65, blue: 0.20))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(red: 0.98, green: 0.65, blue: 0.20).opacity(0.18))
                                    .clipShape(Capsule())
                            }
                            
                            Text("Files are immediately erased without filling the Trash. Reclaims storage space right away. Cannot be undone.")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.65))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(!selectedDeletionMode ? Color.white.opacity(0.09) : Color.white.opacity(0.03))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(!selectedDeletionMode ? Color(red: 0.98, green: 0.25, blue: 0.65).opacity(0.6) : Color.white.opacity(0.08), lineWidth: !selectedDeletionMode ? 1.5 : 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            
            Text("You can change this preference anytime in Settings.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func featureBullet(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.98, green: 0.25, blue: 0.65))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
        }
    }
    
    private func refreshPermissions() {
        hasFDA = PermissionManager.shared.checkFullDiskAccess()
    }
    
    private func completeSetup() {
        viewModel.moveToTrashOnly = selectedDeletionMode
        UserDefaults.standard.set(selectedDeletionMode, forKey: "moveToTrashOnly")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            viewModel.hasCompletedOnboarding = true
            isPresented = false
        }
        
        // Auto-trigger initial Smart Scan
        viewModel.startSmartScan()
    }
}
