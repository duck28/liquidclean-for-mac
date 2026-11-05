import SwiftUI

public struct SidebarView: View {
    @ObservedObject var viewModel: AppViewModel
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Branding Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.98, green: 0.25, blue: 0.65), Color(red: 0.35, green: 0.70, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .shadow(color: Color(red: 0.98, green: 0.25, blue: 0.65).opacity(0.5), radius: 8)
                    
                    Image(systemName: "drop.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("LiquidClean")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("OPEN SOURCE")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 0.95))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 22)
            
            // Navigation Items
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(NavigationItem.allCases) { item in
                        sidebarButton(for: item)
                    }
                }
                .padding(.horizontal, 12)
            }
            
            Spacer()
            
            // Bottom Quick System Status Widget
            VStack(spacing: 10) {
                if let ram = viewModel.memoryStats {
                    HStack {
                        Image(systemName: "memorychip")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(red: 0.98, green: 0.25, blue: 0.65))
                        Text("RAM")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("\(Int(ram.usagePercentage * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    GlassProgressBar(
                        progress: ram.usagePercentage,
                        accentGradient: [Color(red: 0.98, green: 0.25, blue: 0.65), Color(red: 0.55, green: 0.25, blue: 0.95)]
                    )
                }
                
                if let disk = viewModel.diskStats {
                    HStack {
                        Image(systemName: "internaldrive")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 0.95))
                        Text("Disk")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("\(Int(disk.usagePercentage * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    GlassProgressBar(
                        progress: disk.usagePercentage,
                        accentGradient: [Color(red: 0.0, green: 0.85, blue: 0.95), Color(red: 0.15, green: 0.55, blue: 0.95)]
                    )
                }
            }
            .padding(14)
            .liquidGlass(cornerRadius: 16)
            .padding(.horizontal, 12)
            .padding(.bottom, 18)
        }
        .frame(width: 230)
        .background {
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow)
                .overlay(Color.black.opacity(0.25))
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)
        }
    }
    
    @ViewBuilder
    private func sidebarButton(for item: NavigationItem) -> some View {
        let isSelected = viewModel.selectedTab == item
        
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                viewModel.selectedTab = item
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.iconName)
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.65))
                    .frame(width: 22)
                
                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.75))
                
                Spacer()
                
                // Badge for items count or size if scanned
                if item == .systemJunk {
                    let totalSys = viewModel.categorySize(.userCaches) + viewModel.categorySize(.systemFiles)
                    if totalSys > 0 {
                        badge(text: ByteCountFormatter.string(fromByteCount: totalSys, countStyle: .file))
                    }
                } else if item == .timeMachine && viewModel.purgeableSpaceBytes > 0 {
                    badge(text: ByteCountFormatter.string(fromByteCount: viewModel.purgeableSpaceBytes, countStyle: .file))
                } else if item == .developerJunk && viewModel.categorySize(.developerJunk) > 0 {
                    badge(text: viewModel.formattedCategorySize(.developerJunk))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    ZStack {
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.2), radius: 6)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func badge(text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.18))
            .clipShape(Capsule())
    }
}
