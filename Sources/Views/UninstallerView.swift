import SwiftUI

public struct UninstallerView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var searchText = ""
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Uninstaller & Leftovers")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Completely remove applications along with all their hidden cache, preferences, and support files.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                
                Spacer()
                
                GlassButton(viewModel.isScanning ? "Scanning..." : "Refresh Apps", icon: "arrow.clockwise") {
                    viewModel.scanApplications()
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.5))
                
                TextField("Search installed applications...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 28)
            
            // Main content split view: List on left, details on right
            HStack(spacing: 18) {
                // Left Column: Apps List
                appsListView
                    .frame(width: 320)
                
                // Right Column: Selected App Breakdown
                if let app = viewModel.selectedApp {
                    appDetailView(app: app)
                } else {
                    noAppSelectedView
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .onAppear {
            if viewModel.installedApps.isEmpty {
                viewModel.scanApplications()
            }
        }
    }
    
    private var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return viewModel.installedApps
        }
        return viewModel.installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.bundleIdentifier ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    @ViewBuilder
    private var appsListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredApps) { app in
                    let isSelected = viewModel.selectedApp?.id == app.id
                    Button {
                        viewModel.selectedApp = app
                    } label: {
                        HStack(spacing: 12) {
                            Image(nsImage: app.appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                
                                Text(app.formattedTotalSize)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.16))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                                    }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .liquidGlass(cornerRadius: 16)
    }
    
    @ViewBuilder
    private func appDetailView(app: AppInfo) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // App Banner
            HStack(spacing: 16) {
                Image(nsImage: app.appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 54, height: 54)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("\(app.bundleIdentifier ?? "No Bundle ID") • Version \(app.version ?? "1.0")")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                    
                    Text("Total Disk Footprint: \(app.formattedTotalSize)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(red: 0.75, green: 0.40, blue: 1.0))
                }
                
                Spacer()
                
                GlassButton("Uninstall App", icon: "trash.fill", style: .destructive) {
                    viewModel.uninstallApp(app)
                }
            }
            .padding(.bottom, 6)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            Text("FILES & RESIDUAL DATA TO CLEAN")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.6))
            
            // Files Breakdown list
            ScrollView {
                VStack(spacing: 10) {
                    // Application Binary row
                    HStack {
                        Image(systemName: "app.fill")
                            .foregroundStyle(Color(red: 0.75, green: 0.40, blue: 1.0))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Application Binary")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(app.bundleURL.path)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.45))
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: app.appBinarySize, countStyle: .file))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // Associated files
                    ForEach(app.associatedItems) { item in
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(Color(red: 0.20, green: 0.85, blue: 0.95))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)
                                Text(item.path)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.45))
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(item.formattedSize)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(22)
        .liquidGlass(cornerRadius: 18, tintColor: Color(red: 0.75, green: 0.40, blue: 1.0))
    }
    
    @ViewBuilder
    private var noAppSelectedView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 38))
                .foregroundStyle(.white.opacity(0.4))
            Text("Select an Application")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text("Select an app from the list on the left to inspect and remove all its residual files.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .liquidGlass(cornerRadius: 18)
    }
}
