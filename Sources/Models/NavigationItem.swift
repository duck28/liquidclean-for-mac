import SwiftUI

public enum NavigationItem: String, CaseIterable, Identifiable, Sendable {
    case smartScan = "Smart Scan"
    case systemJunk = "System Junk"
    case timeMachine = "Time Machine"
    case developerJunk = "Developer Junk"
    case largeFiles = "Large & Old Files"
    case uninstaller = "App Uninstaller"
    case systemPerformance = "Performance"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .smartScan: return "wand.and.stars"
        case .systemJunk: return "trash.circle.fill"
        case .timeMachine: return "clock.arrow.circlepath"
        case .developerJunk: return "hammer.circle.fill"
        case .largeFiles: return "archivebox.circle.fill"
        case .uninstaller: return "square.grid.2x2.fill"
        case .systemPerformance: return "gauge.with.needle.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    public var categoryTag: String {
        switch self {
        case .smartScan: return "RECOMMENDED"
        case .systemJunk, .timeMachine, .developerJunk: return "CLEANUP"
        case .largeFiles: return "FILES"
        case .uninstaller: return "APPLICATIONS"
        case .systemPerformance: return "MONITOR"
        case .settings: return "SYSTEM"
        }
    }
}
