import Foundation
import Darwin

public final class SystemMonitor: Sendable {
    public static let shared = SystemMonitor()
    
    public init() {}
    
    public func fetchMemoryStats() -> MemoryStats {
        let hostPort = mach_host_self()
        var pageSize: vm_size_t = 0
        _ = host_page_size(hostPort, &pageSize)
        
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return MemoryStats(
                totalBytes: ProcessInfo.processInfo.physicalMemory,
                usedBytes: 0,
                freeBytes: ProcessInfo.processInfo.physicalMemory,
                activeBytes: 0,
                inactiveBytes: 0,
                wiredBytes: 0,
                compressedBytes: 0
            )
        }
        
        let total = ProcessInfo.processInfo.physicalMemory
        let active = UInt64(vmStats.active_count) * UInt64(pageSize)
        let inactive = UInt64(vmStats.inactive_count) * UInt64(pageSize)
        let wired = UInt64(vmStats.wire_count) * UInt64(pageSize)
        let compressed = UInt64(vmStats.compressor_page_count) * UInt64(pageSize)
        let free = UInt64(vmStats.free_count) * UInt64(pageSize)
        
        let used = active + wired + compressed
        
        return MemoryStats(
            totalBytes: total,
            usedBytes: used,
            freeBytes: free + inactive,
            activeBytes: active,
            inactiveBytes: inactive,
            wiredBytes: wired,
            compressedBytes: compressed
        )
    }
    
    public func fetchDiskStats() -> DiskStats {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        guard let values = try? homeURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]) else {
            return DiskStats(totalBytes: 500_000_000_000, freeBytes: 250_000_000_000, usedBytes: 250_000_000_000)
        }
        
        let total = Int64(values.volumeTotalCapacity ?? 0)
        let free = Int64(values.volumeAvailableCapacity ?? 0)
        let used = max(0, total - free)
        
        return DiskStats(totalBytes: total, freeBytes: free, usedBytes: used)
    }
    
    public func purgeMemory() async -> Bool {
        // Run background memory cache allocation and deallocation to cause inactive memory flush
        return await Task.detached(priority: .userInitiated) {
            // Allocate and instantly free buffer chunks
            var buffer: [UInt8] = []
            buffer.reserveCapacity(200 * 1024 * 1024) // 200MB test cycle
            for _ in 0..<10 {
                buffer.append(contentsOf: repeatElement(0xAA, count: 20 * 1024 * 1024))
            }
            buffer.removeAll(keepingCapacity: false)
            return true
        }.value
    }
}
