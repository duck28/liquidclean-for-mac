import SwiftUI

public struct DeveloperJunkView: View {
    @ObservedObject var viewModel: AppViewModel
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Developer Junk & Caches")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("DEV")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 0.0, green: 0.90, blue: 0.75))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.0, green: 0.90, blue: 0.75).opacity(0.18))
                            .clipShape(Capsule())
                    }
                    
                    Text("Reclaim massive gigabytes from Xcode DerivedData, CocoaPods, npm, Homebrew, and language caches.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                
                Spacer()
                
                GlassButton("Scan Dev Tools", icon: "hammer.fill") {
                    viewModel.startSmartScan()
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            
            let devItems = viewModel.scannedItemsByCategory[.developerJunk] ?? []
            let totalDevSize = devItems.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
            
            // Sub-header stats bar
            HStack {
                Text("\(devItems.count) developer directories found • \(ByteCountFormatter.string(fromByteCount: totalDevSize, countStyle: .file)) cleanable")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                
                Spacer()
                
                Button("Select All") {
                    viewModel.toggleSelectAll(category: .developerJunk, select: true)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.0, green: 0.90, blue: 0.75))
                
                Text("•")
                    .foregroundStyle(.white.opacity(0.3))
                
                Button("Deselect All") {
                    viewModel.toggleSelectAll(category: .developerJunk, select: false)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 28)
            
            if devItems.isEmpty {
                emptyDevView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(devItems) { item in
                            devItemCard(item: item)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
            }
        }
    }
    
    @ViewBuilder
    private func devItemCard(item: ScannedItem) -> some View {
        HStack(spacing: 16) {
            Button {
                viewModel.toggleItemSelection(category: .developerJunk, id: item.id)
            } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(item.isSelected ? Color(red: 0.0, green: 0.90, blue: 0.75) : .white.opacity(0.3))
            }
            .buttonStyle(.plain)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.0, green: 0.90, blue: 0.75).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconForDevTool(name: item.name))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 0.0, green: 0.90, blue: 0.75))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(item.path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            Text(item.formattedSize)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 80, alignment: .trailing)
            
            Button {
                item.revealInFinder()
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: 16, tintColor: Color(red: 0.0, green: 0.90, blue: 0.75), isInteractive: true)
    }
    
    private func iconForDevTool(name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("xcode") || lower.contains("deriveddata") {
            return "hammer.fill"
        } else if lower.contains("brew") || lower.contains("homebrew") {
            return "mug.fill"
        } else if lower.contains("npm") || lower.contains("yarn") || lower.contains("pnpm") {
            return "shippingbox.fill"
        } else if lower.contains("pip") || lower.contains("uv") {
            return "chevron.left.forwardslash.chevron.right"
        } else if lower.contains("cargo") || lower.contains("rust") {
            return "gearshape.2.fill"
        } else {
            return "terminal.fill"
        }
    }
    
    @ViewBuilder
    private var emptyDevView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "hammer.circle.fill")
                .font(.system(size: 46))
                .foregroundStyle(Color(red: 0.0, green: 0.90, blue: 0.75).opacity(0.7))
            
            Text("No Developer Caches Scanned")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Scan to find Xcode DerivedData, build intermediate files, and package manager cache stores.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
            
            GlassButton("Scan Dev Tools", icon: "hammer.fill") {
                viewModel.startSmartScan()
            }
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
