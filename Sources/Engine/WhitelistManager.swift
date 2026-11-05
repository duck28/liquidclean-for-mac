import Foundation

public final class WhitelistManager: Sendable {
    public static let shared = WhitelistManager()
    
    // Protected patterns and paths that should NEVER be cleaned or removed
    private let protectedSystemPrefixes: [String] = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/private/var/db",
        "/private/var/root"
    ]
    
    private let protectedUserDirectories: [String] = [
        ".ssh",
        ".gnupg",
        ".gitconfig",
        "Keychains",
        "Mobile Documents", // iCloud
        "Mail/V", // Mailboxes
        "Photos Library.photoslibrary"
    ]
    
    public init() {}
    
    public func isProtected(url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        
        for prefix in protectedSystemPrefixes {
            if path.hasPrefix(prefix) {
                return true
            }
        }
        
        for protected in protectedUserDirectories {
            if path.contains("/" + protected) || path.hasSuffix("/" + protected) {
                return true
            }
        }
        
        return false
    }
}
