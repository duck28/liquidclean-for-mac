import Foundation

public final class LargeFileScanner: @unchecked Sendable {
    public static let shared = LargeFileScanner()
    private let fileManager = FileManager.default
    private let whitelist = WhitelistManager.shared
    
    public init() {}
    
    public func scanLargeFiles(
        minSizeBytes: Int64 = 50 * 1024 * 1024, // 50 MB default
        onProgress: (@Sendable (Double, String) -> Void)? = nil
    ) async -> [ScannedItem] {
        var items: [ScannedItem] = []
        let home = fileManager.homeDirectoryForCurrentUser
        
        let searchDirectories: [URL] = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Movies"),
            home.appendingPathComponent("Music")
        ]
        
        let totalDirs = Double(searchDirectories.count)
        
        for (dirIndex, dirURL) in searchDirectories.enumerated() {
            guard fileManager.fileExists(atPath: dirURL.path) else { continue }
            
            let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey]
            guard let enumerator = fileManager.enumerator(
                at: dirURL,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsPackageDescendants],
                errorHandler: { _, _ in true }
            ) else {
                continue
            }
            
            var count = 0
            while let fileURL = enumerator.nextObject() as? URL {
                count += 1
                if count % 25 == 0 {
                    let progress = (Double(dirIndex) + (Double(count) / 2000.0).clamped(to: 0.0...1.0)) / totalDirs
                    onProgress?(progress, fileURL.lastPathComponent)
                }
                
                guard !whitelist.isProtected(url: fileURL) else { continue }
                guard let values = try? fileURL.resourceValues(forKeys: resourceKeys) else { continue }
                
                if values.isDirectory != true {
                    let size = Int64(values.fileSize ?? 0)
                    if size >= minSizeBytes {
                        let item = ScannedItem(
                            url: fileURL,
                            name: fileURL.lastPathComponent,
                            size: size,
                            category: .largeFiles,
                            isSelected: false, // Large files should never be selected by default!
                            isSafe: false,
                            lastModified: values.contentModificationDate,
                            itemDescription: fileKindDescription(for: fileURL)
                        )
                        items.append(item)
                    }
                }
            }
        }
        
        return items.sorted(by: { $0.size > $1.size })
    }
    
    private func fileKindDescription(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "dmg", "iso", "img", "pkg":
            return "Disk Image / Installer"
        case "zip", "tar", "gz", "tgz", "rar", "7z":
            return "Archive"
        case "mp4", "mov", "mkv", "avi", "webm":
            return "Video"
        case "mp3", "flac", "wav", "m4a", "aac":
            return "Audio Track"
        case "pdf", "docx", "pages", "key", "pptx":
            return "Document"
        default:
            return "File (.\(ext))"
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
