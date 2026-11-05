import Foundation

public struct TimeMachineSnapshot: Identifiable, Hashable, Sendable {
    public let id: String
    public let snapshotName: String
    public let dateString: String
    public let formattedDate: String
    public let isPurgeable: Bool
    public var isSelected: Bool
    public var estimatedSizeBytes: Int64
    
    public init(
        id: String,
        snapshotName: String,
        dateString: String,
        formattedDate: String,
        isPurgeable: Bool = true,
        isSelected: Bool = false,
        estimatedSizeBytes: Int64 = 0
    ) {
        self.id = id
        self.snapshotName = snapshotName
        self.dateString = dateString
        self.formattedDate = formattedDate
        self.isPurgeable = isPurgeable
        self.isSelected = isSelected
        self.estimatedSizeBytes = estimatedSizeBytes
    }
    
    public var formattedSize: String {
        if estimatedSizeBytes > 0 {
            return ByteCountFormatter.string(fromByteCount: estimatedSizeBytes, countStyle: .file)
        } else {
            return "Local APFS Snapshot"
        }
    }
}
