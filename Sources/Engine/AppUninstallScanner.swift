import Foundation
import AppKit

public final class AppUninstallScanner: @unchecked Sendable {
    public static let shared = AppUninstallScanner()
    private let fileManager = FileManager.default
    
    public init() {}
    
    public func scanInstalledApplications(
        onProgress: (@Sendable (Double, String) -> Void)? = nil
    ) async -> [AppInfo] {
        var appList: [AppInfo] = []
        let home = fileManager.homeDirectoryForCurrentUser
        
        let appDirectories = [
            URL(fileURLWithPath: "/Applications"),
            home.appendingPathComponent("Applications")
        ]
        
        var appURLs: [URL] = []
        for dir in appDirectories {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            for item in contents where item.pathExtension == "app" {
                appURLs.append(item)
            }
        }
        
        let total = Double(appURLs.count)
        for (index, appURL) in appURLs.enumerated() {
            onProgress?(Double(index) / max(total, 1.0), appURL.lastPathComponent)
            
            guard let bundle = Bundle(url: appURL) else { continue }
            let name = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
                ?? (bundle.infoDictionary?["CFBundleName"] as? String)
                ?? appURL.deletingPathExtension().lastPathComponent
            
            // Skip Apple system apps in /Applications/Utilities or System
            if appURL.path.contains("/System/") { continue }
            
            let bundleID = bundle.bundleIdentifier
            let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
            let binarySize = calculateAppSize(url: appURL)
            
            // Discover associated residual items
            let associated = findAssociatedFiles(appName: name, bundleIdentifier: bundleID, home: home)
            
            let appInfo = AppInfo(
                name: name,
                bundleIdentifier: bundleID,
                bundleURL: appURL,
                version: version,
                appBinarySize: binarySize,
                associatedItems: associated
            )
            appList.append(appInfo)
        }
        
        return appList.sorted(by: { $0.totalSize > $1.totalSize })
    }
    
    private func findAssociatedFiles(appName: String, bundleIdentifier: String?, home: URL) -> [ScannedItem] {
        var items: [ScannedItem] = []
        
        let searchLocations: [(URL, String)] = [
            (home.appendingPathComponent("Library/Application Support"), "Application Support"),
            (home.appendingPathComponent("Library/Caches"), "Caches"),
            (home.appendingPathComponent("Library/Saved Application State"), "Saved State"),
            (home.appendingPathComponent("Library/WebKit"), "WebKit Storage"),
            (home.appendingPathComponent("Library/Logs"), "Logs")
        ]
        
        for (baseDir, label) in searchLocations {
            // Check by bundle ID
            if let bid = bundleIdentifier {
                let candidateURL = baseDir.appendingPathComponent(bid)
                if fileManager.fileExists(atPath: candidateURL.path) {
                    let size = JunkScanner.shared.calculateSize(of: candidateURL)
                    items.append(
                        ScannedItem(
                            url: candidateURL,
                            name: "\(candidateURL.lastPathComponent) (\(label))",
                            size: size,
                            category: .appLeftovers,
                            isSelected: true,
                            isSafe: true,
                            itemDescription: "\(appName) \(label)"
                        )
                    )
                }
            }
            
            // Check by app name
            let candidateURL = baseDir.appendingPathComponent(appName)
            if fileManager.fileExists(atPath: candidateURL.path) && !items.contains(where: { $0.url == candidateURL }) {
                let size = JunkScanner.shared.calculateSize(of: candidateURL)
                items.append(
                    ScannedItem(
                        url: candidateURL,
                        name: "\(candidateURL.lastPathComponent) (\(label))",
                        size: size,
                        category: .appLeftovers,
                        isSelected: true,
                        isSafe: true,
                        itemDescription: "\(appName) \(label)"
                    )
                )
            }
        }
        
        // Preferences plist
        if let bid = bundleIdentifier {
            let prefURL = home.appendingPathComponent("Library/Preferences/\(bid).plist")
            if fileManager.fileExists(atPath: prefURL.path) {
                let size = (try? prefURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                items.append(
                    ScannedItem(
                        url: prefURL,
                        name: "\(bid).plist (Preferences)",
                        size: Int64(size),
                        category: .appLeftovers,
                        isSelected: true,
                        isSafe: true,
                        itemDescription: "\(appName) Preferences plist"
                    )
                )
            }
        }
        
        return items
    }
    
    private func calculateAppSize(url: URL) -> Int64 {
        JunkScanner.shared.calculateSize(of: url)
    }
}
