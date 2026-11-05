import SwiftUI

public struct SystemPerformanceView: View {
    @ObservedObject var viewModel: AppViewModel
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Performance & Health")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Real-time telemetry of memory pressure, physical RAM allocation, and storage.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    
                    Spacer()
                    
                    GlassButton("Refresh", icon: "arrow.clockwise") {
                        viewModel.refreshSystemStats()
                    }
                }
                .padding(.top, 24)
                
                // Primary Metrics Row
                HStack(spacing: 18) {
                    if let ram = viewModel.memoryStats {
                        MetricGaugeView(
                            title: "Physical Memory (RAM)",
                            valueText: "\(ram.formattedUsed) / \(ram.formattedTotal)",
                            subtitle: "\(ram.formattedFree) Free",
                            percentage: ram.usagePercentage,
                            gradient: [Color(red: 0.98, green: 0.25, blue: 0.65), Color(red: 0.65, green: 0.15, blue: 0.95)],
                            icon: "memorychip"
                        )
                    }
                    
                    if let disk = viewModel.diskStats {
                        MetricGaugeView(
                            title: "Macintosh HD (Storage)",
                            valueText: "\(disk.formattedUsed) / \(disk.formattedTotal)",
                            subtitle: "\(disk.formattedFree) Available",
                            percentage: disk.usagePercentage,
                            gradient: [Color(red: 0.0, green: 0.85, blue: 0.95), Color(red: 0.15, green: 0.55, blue: 0.95)],
                            icon: "internaldrive"
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Memory Breakdown Card
                if let ram = viewModel.memoryStats {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("Memory Breakdown")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            GlassButton(
                                viewModel.isPurgingMemory ? "Freeing RAM..." : "Free Up RAM",
                                icon: "bolt.fill",
                                style: .primary(colors: [Color(red: 0.98, green: 0.25, blue: 0.65), Color(red: 0.45, green: 0.15, blue: 0.85)])
                            ) {
                                viewModel.purgeRAM()
                            }
                        }
                        
                        // Full width stretched memory bubbles
                        HStack(spacing: 12) {
                            memoryDetailPill(
                                label: "Active",
                                value: ByteCountFormatter.string(fromByteCount: Int64(ram.activeBytes), countStyle: .memory),
                                color: Color(red: 0.98, green: 0.25, blue: 0.65)
                            )
                            memoryDetailPill(
                                label: "Wired (OS Kernel)",
                                value: ByteCountFormatter.string(fromByteCount: Int64(ram.wiredBytes), countStyle: .memory),
                                color: Color(red: 0.95, green: 0.35, blue: 0.25)
                            )
                            memoryDetailPill(
                                label: "Compressed",
                                value: ByteCountFormatter.string(fromByteCount: Int64(ram.compressedBytes), countStyle: .memory),
                                color: Color(red: 0.75, green: 0.40, blue: 1.0)
                            )
                            memoryDetailPill(
                                label: "Inactive & Free",
                                value: ByteCountFormatter.string(fromByteCount: Int64(ram.freeBytes), countStyle: .memory),
                                color: Color(red: 0.20, green: 0.85, blue: 0.55)
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .liquidGlass(cornerRadius: 18)
                }
                
                // Hardware Info Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Host Architecture & Hardware")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    let storageConfig: String = {
                        if let disk = viewModel.diskStats {
                            return "\(disk.formattedTotal) (APFS SSD)"
                        }
                        return "Macintosh HD (APFS)"
                    }()
                    
                    HStack(spacing: 12) {
                        infoStat(
                            label: "Processor Cores",
                            value: "\(ProcessInfo.processInfo.processorCount) Cores",
                            icon: "cpu",
                            color: Color(red: 0.98, green: 0.25, blue: 0.65)
                        )
                        infoStat(
                            label: "Operating System",
                            value: ProcessInfo.processInfo.operatingSystemVersionString,
                            icon: "apple.logo",
                            color: Color(red: 0.25, green: 0.65, blue: 1.0)
                        )
                        infoStat(
                            label: "Hardware Platform",
                            value: "Apple Silicon",
                            icon: "laptopcomputer",
                            color: Color(red: 0.75, green: 0.40, blue: 1.0)
                        )
                        infoStat(
                            label: "Total Mac Storage",
                            value: storageConfig,
                            icon: "internaldrive.fill",
                            color: Color(red: 0.0, green: 0.90, blue: 0.75)
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .liquidGlass(cornerRadius: 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
    }
    
    @ViewBuilder
    private func memoryDetailPill(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    @ViewBuilder
    private func infoStat(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
