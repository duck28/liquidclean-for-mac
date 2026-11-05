import Foundation

public enum TimeMachineError: LocalizedError, Sendable {
    case executionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .executionFailed(let msg): return msg
        }
    }
}

public final class TimeMachineManager: @unchecked Sendable {
    public static let shared = TimeMachineManager()
    
    public init() {}
    
    public func fetchPurgeableSpace() -> Int64 {
        let rootURL = URL(fileURLWithPath: "/")
        guard let values = try? rootURL.resourceValues(forKeys: [
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ]) else {
            return 0
        }
        
        let normal = Int64(values.volumeAvailableCapacity ?? 0)
        let important = values.volumeAvailableCapacityForImportantUsage ?? 0
        let purgeable = max(0, important - normal)
        return purgeable
    }
    
    public func listLocalSnapshots() async -> [TimeMachineSnapshot] {
        return await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
            process.arguments = ["listlocalsnapshotdates", "/"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let output = String(data: data, encoding: .utf8) else { return [] }
                
                var snapshots: [TimeMachineSnapshot] = []
                let lines = output.components(separatedBy: .newlines)
                
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty, !trimmed.starts(with: "Snapshot dates") else { continue }
                    
                    let formatted = Self.formatSnapshotDate(trimmed)
                    snapshots.append(
                        TimeMachineSnapshot(
                            id: trimmed,
                            snapshotName: "com.apple.TimeMachine.\(trimmed).local",
                            dateString: trimmed,
                            formattedDate: formatted,
                            isPurgeable: true,
                            isSelected: false
                        )
                    )
                }
                
                if snapshots.isEmpty {
                    snapshots = Self.fetchSnapshotsFallback()
                }
                
                return snapshots
            } catch {
                return Self.fetchSnapshotsFallback()
            }
        }.value
    }
    
    private static func fetchSnapshotsFallback() -> [TimeMachineSnapshot] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
        process.arguments = ["listlocalsnapshots", "/"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            var snapshots: [TimeMachineSnapshot] = []
            let lines = output.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.contains("com.apple.TimeMachine.") else { continue }
                
                let cleaned = trimmed
                    .replacingOccurrences(of: "com.apple.TimeMachine.", with: "")
                    .replacingOccurrences(of: ".local", with: "")
                
                let formatted = formatSnapshotDate(cleaned)
                snapshots.append(
                    TimeMachineSnapshot(
                        id: cleaned,
                        snapshotName: trimmed,
                        dateString: cleaned,
                        formattedDate: formatted,
                        isPurgeable: true,
                        isSelected: false
                    )
                )
            }
            return snapshots
        } catch {
            return []
        }
    }
    
    private static func formatSnapshotDate(_ dateString: String) -> String {
        let parts = dateString.split(separator: "-")
        guard parts.count >= 4 else { return dateString }
        let year = parts[0]
        let month = parts[1]
        let day = parts[2]
        let timePart = parts[3]
        
        if timePart.count == 6 {
            let hour = timePart.prefix(2)
            let minute = timePart.dropFirst(2).prefix(2)
            let second = timePart.suffix(2)
            return "\(year)-\(month)-\(day) at \(hour):\(minute):\(second)"
        }
        return "\(year)-\(month)-\(day) \(timePart)"
    }
    
    public func deleteSnapshot(dateString: String) async -> Result<Void, TimeMachineError> {
        let task = Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
            process.arguments = ["deletelocalsnapshots", dateString]
            
            let errPipe = Pipe()
            process.standardError = errPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    return Result<Void, TimeMachineError>.success(())
                } else {
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    let msg = String(data: errData, encoding: .utf8) ?? "Failed with exit code \(process.terminationStatus)"
                    return Result<Void, TimeMachineError>.failure(.executionFailed(msg.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
            } catch {
                return Result<Void, TimeMachineError>.failure(.executionFailed(error.localizedDescription))
            }
        }
        return await task.value
    }
    
    public func thinSnapshots(amountBytes: Int64 = 10_000_000_000) async -> Result<Void, TimeMachineError> {
        let task = Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
            process.arguments = ["thinlocalsnapshots", "/", "\(amountBytes)", "4"]
            
            let errPipe = Pipe()
            process.standardError = errPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    return Result<Void, TimeMachineError>.success(())
                } else {
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    let msg = String(data: errData, encoding: .utf8) ?? "Failed with status \(process.terminationStatus)"
                    return Result<Void, TimeMachineError>.failure(.executionFailed(msg.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
            } catch {
                return Result<Void, TimeMachineError>.failure(.executionFailed(error.localizedDescription))
            }
        }
        return await task.value
    }
}
