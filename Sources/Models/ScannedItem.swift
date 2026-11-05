import Foundation
import AppKit

public struct ScannedItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let path: String
    public let size: Int64
    public let category: JunkCategory
    public var isSelected: Bool
    public let isSafe: Bool
    public let lastModified: Date?
    public let itemDescription: String?
    
    public init(
        id: UUID = UUID(),
        url: URL,
        name: String? = nil,
        size: Int64,
        category: JunkCategory,
        isSelected: Bool = true,
        isSafe: Bool = true,
        lastModified: Date? = nil,
        itemDescription: String? = nil
    ) {
        self.id = id
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.path = url.path
        self.size = size
        self.category = category
        self.isSelected = isSelected
        self.isSafe = isSafe
        self.lastModified = lastModified
        self.itemDescription = itemDescription
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    public var formattedDate: String {
        guard let date = lastModified else { return "Unknown date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    public func revealInFinder() {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}
