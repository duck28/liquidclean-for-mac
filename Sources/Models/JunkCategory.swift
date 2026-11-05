import SwiftUI

public enum JunkCategory: String, CaseIterable, Identifiable, Sendable {
    case userCaches = "User Caches"
    case systemFiles = "System & Mail Junk"
    case systemLogs = "Diagnostic & Crash Logs"
    case developerJunk = "Developer Caches"
    case browserCaches = "Browser Data"
    case trash = "Trash Bins"
    case appLeftovers = "App Leftovers"
    case largeFiles = "Large & Old Files"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .userCaches: return "sparkles"
        case .systemFiles: return "macwindow.and.cursor"
        case .systemLogs: return "doc.text.magnifyingglass"
        case .developerJunk: return "hammer.fill"
        case .browserCaches: return "globe"
        case .trash: return "trash.fill"
        case .appLeftovers: return "puzzlepiece.extension.fill"
        case .largeFiles: return "internaldrive.fill"
        }
    }
    
    public var accentColors: [Color] {
        switch self {
        case .userCaches:
            return [Color(red: 0.98, green: 0.28, blue: 0.65), Color(red: 0.65, green: 0.18, blue: 0.95)] // Magenta to Violet
        case .systemFiles:
            return [Color(red: 0.20, green: 0.60, blue: 1.0), Color(red: 0.10, green: 0.35, blue: 0.90)] // Sky to Cobalt
        case .systemLogs:
            return [Color(red: 0.30, green: 0.70, blue: 0.95), Color(red: 0.15, green: 0.45, blue: 0.85)] // Azure
        case .developerJunk:
            return [Color(red: 0.0, green: 0.90, blue: 0.75), Color(red: 0.15, green: 0.70, blue: 0.95)] // Cyan to Ocean
        case .browserCaches:
            return [Color(red: 1.0, green: 0.65, blue: 0.20), Color(red: 0.95, green: 0.35, blue: 0.20)] // Amber to Coral
        case .trash:
            return [Color(red: 0.95, green: 0.30, blue: 0.30), Color(red: 0.75, green: 0.15, blue: 0.35)] // Crimson to Burgundy
        case .appLeftovers:
            return [Color(red: 0.75, green: 0.40, blue: 1.0), Color(red: 0.45, green: 0.20, blue: 0.85)] // Purple to Iris
        case .largeFiles:
            return [Color(red: 0.20, green: 0.85, blue: 0.55), Color(red: 0.10, green: 0.65, blue: 0.70)] // Emerald to Teal
        }
    }
    
    public var primaryColor: Color {
        accentColors.first ?? .cyan
    }
    
    public var subtitle: String {
        switch self {
        case .userCaches:
            return "Application cache files safely rebuilt by macOS on demand"
        case .systemFiles:
            return "Mail downloads, iOS firmware IPSW, incomplete downloads, & system media caches"
        case .systemLogs:
            return "Diagnostic reports, crash logs, and system logging buffers"
        case .developerJunk:
            return "Xcode DerivedData, CocoaPods, npm, and Homebrew caches"
        case .browserCaches:
            return "Cached web assets from Safari, Chrome, and browsers"
        case .trash:
            return "Items sitting in user and external volume trash cans"
        case .appLeftovers:
            return "Residual files left behind by uninstalled applications"
        case .largeFiles:
            return "Rarely accessed files consuming substantial disk space"
        }
    }
    
    public var isSafeByDefault: Bool {
        switch self {
        case .userCaches, .systemFiles, .systemLogs, .developerJunk, .browserCaches:
            return true
        case .trash, .appLeftovers, .largeFiles:
            return false // User should review first
        }
    }
}
