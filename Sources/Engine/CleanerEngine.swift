import Foundation

public struct CleanupResult: Sendable {
    public let itemsRemovedCount: Int
    public let bytesFreed: Int64
    public let errors: [String]
    
    public var formattedBytesFreed: String {
        ByteCountFormatter.string(fromByteCount: bytesFreed, countStyle: .file)
    }
}

public final class CleanerEngine: @unchecked Sendable {
    public static let shared = CleanerEngine()
    private let fileManager = FileManager.default
    private let whitelist = WhitelistManager.shared
    
    public init() {}
    
    public func cleanItems(
        _ items: [ScannedItem],
        moveToTrash: Bool = true,
        onProgress: (@Sendable (Double, String) -> Void)? = nil
    ) async -> CleanupResult {
        var removedCount = 0
        var freedBytes: Int64 = 0
        var errors: [String] = []
        
        let total = Double(items.count)
        
        for (index, item) in items.enumerated() {
            guard item.isSelected else { continue }
            guard !whitelist.isProtected(url: item.url) else {
                errors.append("Skipped protected path: \(item.path)")
                continue
            }
            
            onProgress?(Double(index) / max(total, 1.0), item.name)
            
            do {
                if moveToTrash {
                    // Safe cleanup: Move to user Trash
                    var resultingURL: NSURL?
                    try fileManager.trashItem(at: item.url, resultingItemURL: &resultingURL)
                } else {
                    // Direct removal
                    try fileManager.removeItem(at: item.url)
                }
                removedCount += 1
                freedBytes += item.size
            } catch {
                errors.append("Failed to clean \(item.name): \(error.localizedDescription)")
            }
        }
        
        return CleanupResult(itemsRemovedCount: removedCount, bytesFreed: freedBytes, errors: errors)
    }
}
