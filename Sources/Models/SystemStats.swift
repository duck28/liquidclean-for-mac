import Foundation

public struct MemoryStats: Sendable {
    public let totalBytes: UInt64
    public let usedBytes: UInt64
    public let freeBytes: UInt64
    public let activeBytes: UInt64
    public let inactiveBytes: UInt64
    public let wiredBytes: UInt64
    public let compressedBytes: UInt64
    
    public var usagePercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }
    
    public var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: Int64(usedBytes), countStyle: .memory)
    }
    
    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .memory)
    }
    
    public var formattedFree: String {
        ByteCountFormatter.string(fromByteCount: Int64(freeBytes), countStyle: .memory)
    }
}

public struct DiskStats: Sendable {
    public let totalBytes: Int64
    public let freeBytes: Int64
    public let usedBytes: Int64
    
    public var usagePercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }
    
    public var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .file)
    }
    
    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    public var formattedFree: String {
        ByteCountFormatter.string(fromByteCount: freeBytes, countStyle: .file)
    }
}

public struct CPUStats: Sendable {
    public let usagePercentage: Double
    public let coreCount: Int
}
