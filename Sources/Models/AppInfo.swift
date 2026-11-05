import Foundation
import AppKit

public struct AppInfo: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let bundleIdentifier: String?
    public let bundleURL: URL
    public let version: String?
    public let appBinarySize: Int64
    public var associatedItems: [ScannedItem]
    public var isSelected: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String?,
        bundleURL: URL,
        version: String?,
        appBinarySize: Int64,
        associatedItems: [ScannedItem] = [],
        isSelected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.bundleURL = bundleURL
        self.version = version
        self.appBinarySize = appBinarySize
        self.associatedItems = associatedItems
        self.isSelected = isSelected
    }
    
    public var totalSize: Int64 {
        appBinarySize + associatedItems.reduce(0) { $0 + $1.size }
    }
    
    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    public var appIcon: NSImage {
        NSWorkspace.shared.icon(forFile: bundleURL.path)
    }
    
    public func revealInFinder() {
        NSWorkspace.shared.selectFile(bundleURL.path, inFileViewerRootedAtPath: "")
    }
}
