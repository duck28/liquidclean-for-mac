import SwiftUI

public struct TimeMachineView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isThinning = false
    @State private var alertMessage: String? = nil
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Time Machine & Local Snapshots")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text("APFS")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(red: 0.98, green: 0.65, blue: 0.20))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.98, green: 0.65, blue: 0.20).opacity(0.18))
                                .clipShape(Capsule())
                        }
                        
                        Text("Manage invisible APFS restore points created by Time Machine that consume gigabytes of purgeable disk space.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    
                    Spacer()
                    
                    GlassButton("Scan Snapshots", icon: "arrow.clockwise") {
                        viewModel.scanTimeMachineSnapshots()
                    }
                }
                .padding(.top, 24)
                
                // Hero Purgeable Space Card
                purgeableSpaceCard
                
                // Snapshot list section header
                HStack {
                    Text("\(viewModel.timeMachineSnapshots.count) Local Restore Points Found")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    if !viewModel.timeMachineSnapshots.isEmpty {
                        Text("Generated automatically by macOS before updates or backups")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                
                // Snapshot items or empty state
                if viewModel.timeMachineSnapshots.isEmpty {
                    emptySnapshotView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.timeMachineSnapshots) { snapshot in
                            snapshotRow(snapshot: snapshot)
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .onAppear {
            viewModel.scanTimeMachineSnapshots()
        }
    }
    
    @ViewBuilder
    private var purgeableSpaceCard: some View {
        let purgeable = viewModel.purgeableSpaceBytes
        
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.65, blue: 0.20), Color(red: 0.95, green: 0.35, blue: 0.20)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color(red: 0.98, green: 0.65, blue: 0.20).opacity(0.4), radius: 10)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("APFS Purgeable Storage")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(purgeable > 0
                     ? "\(ByteCountFormatter.string(fromByteCount: purgeable, countStyle: .file)) of space is tied up in snapshots and purgeable cache."
                     : "No excessive snapshot storage detected on your primary disk.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            GlassButton(
                isThinning ? "Thinning..." : "Thin Snapshots",
                icon: "bolt.fill",
                style: .primary(colors: [Color(red: 0.98, green: 0.65, blue: 0.20), Color(red: 0.95, green: 0.35, blue: 0.20)])
            ) {
                thinSnapshots()
            }
            .disabled(isThinning)
        }
        .padding(20)
        .liquidGlass(cornerRadius: 18, tintColor: Color(red: 0.98, green: 0.65, blue: 0.20))
    }
    
    @ViewBuilder
    private func snapshotRow(snapshot: TimeMachineSnapshot) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.98, green: 0.65, blue: 0.20).opacity(0.15))
                    .frame(width: 42, height: 42)
                
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 0.98, green: 0.65, blue: 0.20))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Snapshot \(snapshot.formattedDate)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(snapshot.snapshotName)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text("Safe to remove")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(red: 0.20, green: 0.85, blue: 0.55))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(red: 0.20, green: 0.85, blue: 0.55).opacity(0.12))
                .clipShape(Capsule())
            
            Button {
                deleteSnapshot(snapshot)
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0.95, green: 0.30, blue: 0.30))
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Delete local snapshot")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: 16, tintColor: Color(red: 0.98, green: 0.65, blue: 0.20), isInteractive: true)
    }
    
    @ViewBuilder
    private var emptySnapshotView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundStyle(Color(red: 0.98, green: 0.65, blue: 0.20).opacity(0.7))
            
            Text("No Local Time Machine Snapshots")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Your Mac currently has no orphaned local APFS restore points. When Time Machine creates local backup points, they will appear here.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
            
            GlassButton("Check Again", icon: "arrow.clockwise") {
                viewModel.scanTimeMachineSnapshots()
            }
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    private func thinSnapshots() {
        isThinning = true
        Task {
            _ = await TimeMachineManager.shared.thinSnapshots(amountBytes: 20_000_000_000)
            viewModel.scanTimeMachineSnapshots()
            viewModel.refreshSystemStats()
            isThinning = false
        }
    }
    
    private func deleteSnapshot(_ snapshot: TimeMachineSnapshot) {
        Task {
            _ = await TimeMachineManager.shared.deleteSnapshot(dateString: snapshot.dateString)
            viewModel.scanTimeMachineSnapshots()
            viewModel.refreshSystemStats()
        }
    }
}
