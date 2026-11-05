import SwiftUI

public struct SmartScanView: View {
    @ObservedObject var viewModel: AppViewModel
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Top Header
                VStack(spacing: 6) {
                    Text("Smart Cleanup")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Analyze system junk, developer artifacts, and reclaim disk space")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.top, 24)
                
                // Central Iconic Scanner Rings
                LiquidScannerRings(state: viewModel.scannerState, size: 240)
                    .padding(.vertical, 8)
                
                // Real-time Scan / Action Status Text
                statusSection
                
                // Action Buttons
                actionButtons
                
                // Category Preview Cards Grid
                categoryCardsGrid
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 40)
        }
    }
    
    @ViewBuilder
    private var statusSection: some View {
        switch viewModel.scannerState {
        case .idle:
            Text("Ready to inspect caches, logs, developer junk, and temporary files safely.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
        case .scanning(let progress, let path):
            VStack(spacing: 12) {
                GlassProgressBar(progress: progress)
                    .frame(maxWidth: 420)
                
                Text(path)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 480)
            }
            
        case .readyToClean(let bytes):
            VStack(spacing: 6) {
                Text("\(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)) of safely removable junk found")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Select items below or perform a 1-click clean to reclaim your disk space.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
            }
            
        case .completed(let bytesFreed):
            VStack(spacing: 6) {
                Text("Cleanup Complete! Reclaimed \(ByteCountFormatter.string(fromByteCount: bytesFreed, countStyle: .file))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.20, green: 0.95, blue: 0.60))
                
                Text("Your Mac is running leaner and cleaner.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 16) {
            switch viewModel.scannerState {
            case .idle:
                GlassButton("Start Smart Scan", icon: "sparkles") {
                    viewModel.startSmartScan()
                }
                
            case .scanning:
                GlassButton("Scanning...", icon: "rays", style: .secondary) {}
                    .disabled(true)
                
            case .readyToClean(let bytes):
                GlassButton(
                    "Clean \(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))",
                    icon: "trash.fill",
                    style: .primary(colors: [Color(red: 0.98, green: 0.25, blue: 0.65), Color(red: 0.65, green: 0.15, blue: 0.95)])
                ) {
                    viewModel.performClean()
                }
                
                GlassButton("Scan Again", icon: "arrow.clockwise", style: .secondary) {
                    viewModel.startSmartScan()
                }
                
            case .completed:
                GlassButton("Done", icon: "checkmark", style: .primary(colors: [Color(red: 0.15, green: 0.85, blue: 0.60), Color(red: 0.05, green: 0.65, blue: 0.50)])) {
                    viewModel.scannerState = .idle
                }
                
                GlassButton("Scan Again", icon: "arrow.clockwise", style: .secondary) {
                    viewModel.startSmartScan()
                }
            }
        }
    }
    
    @ViewBuilder
    private var categoryCardsGrid: some View {
        let displayCategories: [JunkCategory] = [.userCaches, .systemFiles, .developerJunk, .browserCaches, .systemLogs, .trash]
        
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(displayCategories) { cat in
                    categoryCard(for: cat)
                }
            }
            
            // Time Machine Snapshot Notice Banner if purgeable space exists
            if viewModel.purgeableSpaceBytes > 0 || !viewModel.timeMachineSnapshots.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(red: 0.98, green: 0.65, blue: 0.20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Time Machine APFS Snapshots Detected")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("\(ByteCountFormatter.string(fromByteCount: viewModel.purgeableSpaceBytes, countStyle: .file)) purgeable storage in local restore points.")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    
                    Spacer()
                    
                    Button("Manage Snapshots") {
                        withAnimation {
                            viewModel.selectedTab = .timeMachine
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.98, green: 0.65, blue: 0.20))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .liquidGlass(cornerRadius: 14, tintColor: Color(red: 0.98, green: 0.65, blue: 0.20))
            }
        }
        .padding(.top, 12)
    }
    
    @ViewBuilder
    private func categoryCard(for category: JunkCategory) -> some View {
        let size = viewModel.categorySize(category)
        let count = viewModel.selectedCategoryCount(category)
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: category.accentColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                if size > 0 {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                } else if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("0 KB")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(category.subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }
            
            if size > 0 {
                HStack {
                    Text("\(count) items selected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(category.primaryColor)
                    
                    Spacer()
                    
                    Button("Review") {
                        withAnimation {
                            if category == .developerJunk {
                                viewModel.selectedTab = .developerJunk
                            } else {
                                viewModel.selectedTab = .systemJunk
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 18, tintColor: category.primaryColor, isInteractive: true)
    }
}
