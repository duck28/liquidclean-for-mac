import SwiftUI

public struct SystemJunkView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedFilter: JunkCategory = .userCaches
    
    private let availableCategories: [JunkCategory] = [.userCaches, .systemFiles, .systemLogs, .browserCaches, .trash]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Junk & Logs")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Reclaim disk space taken by user application caches, crash logs, and browser storage.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                
                Spacer()
                
                GlassButton("Scan Caches", icon: "arrow.clockwise") {
                    viewModel.startSmartScan()
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            
            // Category Filter Pills
            HStack(spacing: 12) {
                ForEach(availableCategories) { cat in
                    filterPill(for: cat)
                }
            }
            .padding(.horizontal, 28)
            
            // Sub-header with Selection actions & Size
            HStack {
                let items = viewModel.scannedItemsByCategory[selectedFilter] ?? []
                let selectedCount = items.filter { $0.isSelected }.count
                let totalSize = items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
                
                Text("\(selectedCount) of \(items.count) selected (\(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                
                Spacer()
                
                Button("Select All") {
                    viewModel.toggleSelectAll(category: selectedFilter, select: true)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 0.95))
                
                Text("•")
                    .foregroundStyle(.white.opacity(0.3))
                
                Button("Deselect All") {
                    viewModel.toggleSelectAll(category: selectedFilter, select: false)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 28)
            
            // Items List
            let items = viewModel.scannedItemsByCategory[selectedFilter] ?? []
            if items.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(items) { item in
                            itemRow(item: item)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
            }
        }
    }
    
    @ViewBuilder
    private func filterPill(for cat: JunkCategory) -> some View {
        let isSelected = selectedFilter == cat
        let size = viewModel.categorySize(cat)
        
        Button {
            selectedFilter = cat
        } label: {
            HStack(spacing: 6) {
                Image(systemName: cat.iconName)
                    .font(.system(size: 12, weight: .bold))
                Text(cat.rawValue)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                if size > 0 {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : .white.opacity(0.65))
            .background {
                if isSelected {
                    Capsule()
                        .fill(LinearGradient(colors: cat.accentColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: cat.primaryColor.opacity(0.4), radius: 6)
                } else {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func itemRow(item: ScannedItem) -> some View {
        HStack(spacing: 14) {
            Button {
                viewModel.toggleItemSelection(category: selectedFilter, id: item.id)
            } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(item.isSelected ? Color(red: 0.98, green: 0.25, blue: 0.65) : .white.opacity(0.3))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(item.path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            Text(item.formattedSize)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 70, alignment: .trailing)
            
            Button {
                item.revealInFinder()
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(6)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 14, tintColor: selectedFilter.primaryColor, isInteractive: true)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 42))
                .foregroundStyle(Color(red: 0.98, green: 0.25, blue: 0.65).opacity(0.7))
            
            Text("No Junk Items Found Yet")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Run a scan to uncover unnecessary application caches, system logs, and browser caches.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            
            GlassButton("Scan Now", icon: "sparkles") {
                viewModel.startSmartScan()
            }
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
