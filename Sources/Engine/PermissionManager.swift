import Foundation
import AppKit

public final class PermissionManager: Sendable {
    public static let shared = PermissionManager()
    
    public init() {}
    
    public func checkFullDiskAccess() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let safariDir = home.appendingPathComponent("Library/Safari")
        
        // Attempt to read directory contents. Under macOS TCC, this throws or returns nil if FDA is not granted.
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: safariDir.path)
            return true
        } catch {
            return false
        }
    }
    
    public func checkDownloadsAccess() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let downloadsDir = home.appendingPathComponent("Downloads")
        return FileManager.default.isReadableFile(atPath: downloadsDir.path)
    }
    
    public func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
