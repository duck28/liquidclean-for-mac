import Foundation

public final class JunkScanner: @unchecked Sendable {
    public static let shared = JunkScanner()
    private let fileManager = FileManager.default
    private let whitelist = WhitelistManager.shared
    
    public init() {}
    
    public func scanCategory(
        _ category: JunkCategory,
        onProgress: (@Sendable (Double, String) -> Void)? = nil
    ) async -> [ScannedItem] {
        var items: [ScannedItem] = []
        let home = fileManager.homeDirectoryForCurrentUser
        
        switch category {
        case .userCaches:
            let cachesURL = home.appendingPathComponent("Library/Caches")
            items = await scanSubdirectories(in: cachesURL, category: .userCaches, isSafe: true, onProgress: onProgress)
            
        case .systemFiles:
            // Comprehensive System & Mail files
            let systemPaths: [(URL, String, Bool, String)] = [
                (home.appendingPathComponent("Library/Containers/com.apple.mail/Data/Library/Mail Downloads"), "Mail Downloads & Attachments", true, "Downloaded email attachments"),
                (home.appendingPathComponent("Library/Logs/DiagnosticReports"), "Diagnostic Reports & Crash Traces", true, "macOS system crash diagnostics"),
                (URL(fileURLWithPath: "/Library/Logs/DiagnosticReports"), "System Diagnostic Reports", true, "Machine-wide diagnostic logs"),
                (home.appendingPathComponent("Library/Caches/com.apple.QuickLook.thumbnailcache"), "QuickLook Thumbnail Cache", true, "Cached image and file preview thumbnails"),
                (home.appendingPathComponent("Library/Caches/com.apple.Music"), "Apple Music Audio Cache", true, "Streaming audio buffer and artwork"),
                (home.appendingPathComponent("Library/Caches/com.apple.podcasts"), "Podcasts Media Cache", true, "Cached podcast episodes and imagery"),
                (home.appendingPathComponent("Library/Caches/com.apple.TV"), "Apple TV Stream Cache", true, "Cached streaming buffers and video previews"),
                (home.appendingPathComponent("Library/Caches/com.apple.appstore"), "App Store Asset Cache", true, "Temporary app store download artifacts"),
                (home.appendingPathComponent("Library/Caches/com.apple.FontRegistry"), "Font Registry System Cache", true, "Generated font caches"),
                (home.appendingPathComponent("Library/Safari/Favicon Cache"), "Safari Favicon Cache", true, "Saved website icons and graphics"),
                (home.appendingPathComponent("Library/Safari/Touch Icons Cache"), "Safari Touch Icons Cache", true, "Website home screen touch icons"),
                (home.appendingPathComponent("Library/iTunes/iPhone Software Updates"), "iOS Software Updates (IPSW)", true, "Old iOS firmware restoration files"),
                (home.appendingPathComponent("Library/iTunes/iPad Software Updates"), "iPadOS Software Updates (IPSW)", true, "Old iPadOS firmware files"),
                (home.appendingPathComponent("Library/Application Support/MobileSync/Backup"), "iOS Device Local Backups", false, "Local iPhone and iPad device backups")
            ]
            
            let total = Double(systemPaths.count)
            for (idx, (url, name, isSafe, desc)) in systemPaths.enumerated() {
                onProgress?(Double(idx) / total, name)
                if fileManager.fileExists(atPath: url.path) {
                    let size = calculateSize(of: url)
                    if size > 100 * 1024 { // Greater than 100 KB
                        let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                        items.append(
                            ScannedItem(
                                url: url,
                                name: name,
                                size: size,
                                category: .systemFiles,
                                isSelected: isSafe,
                                isSafe: isSafe,
                                lastModified: date,
                                itemDescription: desc
                            )
                        )
                    }
                }
            }
            
            // Scan for incomplete downloads in ~/Downloads
            let incomplete = scanIncompleteDownloads(home: home)
            items.append(contentsOf: incomplete)
            
        case .systemLogs:
            let userLogsURL = home.appendingPathComponent("Library/Logs")
            let systemLogsURL = URL(fileURLWithPath: "/Library/Logs")
            let userLogItems = await scanSubdirectories(in: userLogsURL, category: .systemLogs, isSafe: true, onProgress: onProgress)
            let sysLogItems = await scanSubdirectories(in: systemLogsURL, category: .systemLogs, isSafe: true, onProgress: onProgress)
            items = userLogItems + sysLogItems
            
        case .developerJunk:
            let devPaths: [(URL, String, Bool)] = [
                (home.appendingPathComponent("Library/Developer/Xcode/DerivedData"), "Xcode DerivedData", true),
                (home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport"), "iOS Device Support", true),
                (home.appendingPathComponent("Library/Developer/Xcode/Archives"), "Xcode Archives", false),
                (home.appendingPathComponent("Library/Caches/Homebrew"), "Homebrew Download Cache", true),
                (home.appendingPathComponent(".cocoapods/cache"), "CocoaPods Cache", true),
                (home.appendingPathComponent(".npm"), "npm Package Cache", true),
                (home.appendingPathComponent(".yarn/berry/cache"), "Yarn Cache", true),
                (home.appendingPathComponent(".cache/pnpm"), "pnpm Store Cache", true),
                (home.appendingPathComponent("Library/Caches/pip"), "Python pip Cache", true),
                (home.appendingPathComponent(".cache/uv"), "Astral uv Cache", true),
                (home.appendingPathComponent(".gradle/caches"), "Gradle Build Cache", true),
                (home.appendingPathComponent(".cargo/registry/cache"), "Cargo Rust Cache", true)
            ]
            
            let total = Double(devPaths.count)
            for (idx, (url, description, isSafe)) in devPaths.enumerated() {
                onProgress?(Double(idx) / total, url.lastPathComponent)
                if fileManager.fileExists(atPath: url.path) {
                    let size = calculateSize(of: url)
                    if size > 1024 * 1024 { // Greater than 1 MB
                        items.append(
                            ScannedItem(
                                url: url,
                                name: description,
                                size: size,
                                category: .developerJunk,
                                isSelected: isSafe,
                                isSafe: isSafe,
                                lastModified: (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate,
                                itemDescription: description
                            )
                        )
                    }
                }
            }
            
        case .browserCaches:
            let browserPaths: [(URL, String)] = [
                (home.appendingPathComponent("Library/Caches/com.apple.Safari"), "Safari Web Cache"),
                (home.appendingPathComponent("Library/Caches/Google/Chrome"), "Google Chrome Cache"),
                (home.appendingPathComponent("Library/Caches/BraveSoftware/Brave-Browser"), "Brave Browser Cache"),
                (home.appendingPathComponent("Library/Caches/Microsoft Edge"), "Microsoft Edge Cache"),
                (home.appendingPathComponent("Library/Caches/Firefox"), "Firefox Cache"),
                (home.appendingPathComponent("Library/Caches/com.operasoftware.Opera"), "Opera Cache"),
                (home.appendingPathComponent("Library/Caches/company.thebrowser.Browser"), "Arc Browser Cache")
            ]
            
            for (url, name) in browserPaths {
                if fileManager.fileExists(atPath: url.path) {
                    let size = calculateSize(of: url)
                    if size > 500 * 1024 {
                        items.append(
                            ScannedItem(
                                url: url,
                                name: name,
                                size: size,
                                category: .browserCaches,
                                isSelected: true,
                                isSafe: true,
                                itemDescription: "Cached web content and HTTP objects"
                            )
                        )
                    }
                }
            }
            
        case .trash:
            let trashURL = home.appendingPathComponent(".Trash")
            if fileManager.fileExists(atPath: trashURL.path) {
                let trashItems = await scanTopLevelItems(in: trashURL, category: .trash, isSafe: false, onProgress: onProgress)
                items.append(contentsOf: trashItems)
            }
            
        case .appLeftovers, .largeFiles:
            break
        }
        
        return items.sorted(by: { $0.size > $1.size })
    }
    
    private func scanIncompleteDownloads(home: URL) -> [ScannedItem] {
        let downloadsURL = home.appendingPathComponent("Downloads")
        guard let files = try? fileManager.contentsOfDirectory(
            at: downloadsURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        
        var results: [ScannedItem] = []
        for file in files {
            let ext = file.pathExtension.lowercased()
            if ext == "download" || ext == "crdownload" || ext == "part" {
                let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                if size > 0 {
                    results.append(
                        ScannedItem(
                            url: file,
                            name: file.lastPathComponent,
                            size: Int64(size),
                            category: .systemFiles,
                            isSelected: true,
                            isSafe: true,
                            itemDescription: "Incomplete/interrupted download file"
                        )
                    )
                }
            }
        }
        return results
    }
    
    private func scanSubdirectories(
        in directoryURL: URL,
        category: JunkCategory,
        isSafe: Bool,
        onProgress: (@Sendable (Double, String) -> Void)? = nil
    ) async -> [ScannedItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        var results: [ScannedItem] = []
        let count = Double(contents.count)
        
        for (index, url) in contents.enumerated() {
            guard !whitelist.isProtected(url: url) else { continue }
            onProgress?(Double(index) / max(count, 1.0), url.lastPathComponent)
            
            let size = calculateSize(of: url)
            if size > 1_000_000 { // Items > 1 MB
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                results.append(
                    ScannedItem(
                        url: url,
                        name: url.lastPathComponent,
                        size: size,
                        category: category,
                        isSelected: isSafe,
                        isSafe: isSafe,
                        lastModified: date,
                        itemDescription: "\(category.rawValue) directory"
                    )
                )
            }
        }
        
        return results
    }
    
    private func scanTopLevelItems(
        in directoryURL: URL,
        category: JunkCategory,
        isSafe: Bool,
        onProgress: (@Sendable (Double, String) -> Void)? = nil
    ) async -> [ScannedItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: []
        ) else {
            return []
        }
        
        var results: [ScannedItem] = []
        let count = Double(contents.count)
        
        for (index, url) in contents.enumerated() {
            onProgress?(Double(index) / max(count, 1.0), url.lastPathComponent)
            let size = calculateSize(of: url)
            if size > 0 {
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                results.append(
                    ScannedItem(
                        url: url,
                        name: url.lastPathComponent,
                        size: size,
                        category: category,
                        isSelected: false, // Trash items need explicit check
                        isSafe: isSafe,
                        lastModified: date,
                        itemDescription: "Trashed item"
                    )
                )
            }
        }
        
        return results
    }
    
    public func calculateSize(of url: URL) -> Int64 {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        
        if !isDir.boolValue {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(values?.fileSize ?? 0)
        }
        
        var totalSize: Int64 = 0
        let keys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey]
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else {
            return 0
        }
        
        while let fileURL = enumerator.nextObject() as? URL {
            guard let values = try? fileURL.resourceValues(forKeys: keys) else { continue }
            if values.isDirectory != true {
                totalSize += Int64(values.fileSize ?? 0)
            }
        }
        
        return totalSize
    }
}
