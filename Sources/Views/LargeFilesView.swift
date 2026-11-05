import SwiftUI

public struct LargeFilesView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedKind: String = "All"
    @State private var minSizeFilter: Int64 = 50 * 1024 * 1024 // 50MB
    
    let kindFilters = ["All", "Archive", "Video", "Disk Image", "Document"]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Large & Old Files")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Uncover large files, forgotten downloads, and disk images hoarding your storage.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                
                Spacer()
                
                GlassButton(viewModel.isScanning ? "Scanning..." : "Scan Large Files", icon: "arrow.clockwise") {
                    viewModel.scanLargeFilesList()
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            
            // Filters Bar
            HStack(spacing: 10) {
                ForEach(kindFilters, id: \.self) { kind in
                    Button {
                        selectedKind = kind
                    } label: {
                        Text(kind)
                            .font(.system(size: 12, weight: selectedKind == kind ? .bold : .medium, design: .rounded))
                            .foregroundStyle(selectedKind == kind ? .white : .white.opacity(0.65))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background {
                                if selectedKind == kind {
                                    Capsule()
                                        .fill(LinearGradient(colors: [Color(red: 0.20, green: 0.85, blue: 0.55), Color(red: 0.10, green: 0.65, blue: 0.70)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                } else {
                                    Capsule().fill(Color.white.opacity(0.08))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                let selectedFiles = filteredFiles.filter { $0.isSelected }
                if !selectedFiles.isEmpty {
                    GlassButton("Remove Selected (\(selectedFiles.count))", icon: "trash.fill", style: .destructive) {
                        cleanSelectedLargeFiles()
                    }
                }
            }
            .padding(.horizontal, 28)
            
            // List of files
            if filteredFiles.isEmpty {
                emptyView
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredFiles) { file in
                            largeFileRow(file: file)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            if viewModel.largeFiles.isEmpty {
                viewModel.scanLargeFilesList()
            }
        }
    }
    
    private var filteredFiles: [ScannedItem] {
        if selectedKind == "All" {
            return viewModel.largeFiles
        }
        return viewModel.largeFiles.filter {
            ($0.itemDescription ?? "").localizedCaseInsensitiveContains(selectedKind)
        }
    }
    
    @ViewBuilder
    private func largeFileRow(file: ScannedItem) -> some View {
        HStack(spacing: 14) {
            Button {
                viewModel.toggleLargeFileSelection(id: file.id)
            } label: {
                Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(file.isSelected ? Color(red: 0.20, green: 0.85, blue: 0.55) : .white.opacity(0.3))
            }
            .buttonStyle(.plain)
            
            Image(systemName: fileIcon(for: file.name))
                .font(.system(size: 16))
                .foregroundStyle(Color(red: 0.20, green: 0.85, blue: 0.55))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(file.itemDescription ?? "File")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))
                    
                    Text(file.formattedDate)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            Spacer()
            
            Text(file.formattedSize)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Button {
                file.revealInFinder()
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(6)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 14, tintColor: Color(red: 0.20, green: 0.85, blue: 0.55), isInteractive: true)
    }
    
    private func fileIcon(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "dmg", "iso", "pkg": return "opticaldisc"
        case "zip", "tar", "gz", "7z": return "doc.zipper"
        case "mov", "mp4", "mkv": return "film"
        case "mp3", "flac", "wav": return "music.note"
        default: return "doc"
        }
    }
    
    private func cleanSelectedLargeFiles() {
        let selected = viewModel.largeFiles.filter { $0.isSelected }
        Task {
            _ = await CleanerEngine.shared.cleanItems(selected, moveToTrash: true)
            viewModel.largeFiles.removeAll(where: { $0.isSelected })
            viewModel.refreshSystemStats()
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "internaldrive.fill")
                .font(.system(size: 46))
                .foregroundStyle(Color(red: 0.20, green: 0.85, blue: 0.55).opacity(0.7))
            
            Text(viewModel.isScanning ? "Scanning Large Files..." : "No Large Files Found")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("We look for files greater than 50MB in Downloads, Documents, Desktop, and Movies.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            
            if !viewModel.isScanning {
                GlassButton("Scan Folders", icon: "arrow.clockwise") {
                    viewModel.scanLargeFilesList()
                }
                .padding(.top, 8)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
