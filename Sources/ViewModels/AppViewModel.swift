import SwiftUI
import Combine

@MainActor
public final class AppViewModel: ObservableObject {
    // Navigation
    @Published public var selectedTab: NavigationItem = .smartScan
    
    // Scanner State
    @Published public var scannerState: ScannerState = .idle
    @Published public var isScanning: Bool = false
    @Published public var isCleaning: Bool = false
    @Published public var scanProgress: Double = 0.0
    @Published public var currentScanPath: String = ""
    
    // Scanned data
    @Published public var scannedItemsByCategory: [JunkCategory: [ScannedItem]] = [:]
    @Published public var largeFiles: [ScannedItem] = []
    @Published public var installedApps: [AppInfo] = []
    @Published public var selectedApp: AppInfo? = nil
    @Published public var timeMachineSnapshots: [TimeMachineSnapshot] = []
    @Published public var purgeableSpaceBytes: Int64 = 0
    
    // System Monitor
    @Published public var memoryStats: MemoryStats? = nil
    @Published public var diskStats: DiskStats? = nil
    @Published public var isPurgingMemory: Bool = false
    
    // Settings & Onboarding
    @Published public var moveToTrashOnly: Bool = true
    @Published public var cleanCelebration: Bool = false
    @Published public var lastCleanResult: CleanupResult? = nil
    @Published public var hasCompletedOnboarding: Bool = false
    @Published public var showOnboardingModal: Bool = false
    
    private let junkScanner = JunkScanner.shared
    private let cleanerEngine = CleanerEngine.shared
    private let largeFileScanner = LargeFileScanner.shared
    private let appScanner = AppUninstallScanner.shared
    private let systemMonitor = SystemMonitor.shared
    private let timeMachineManager = TimeMachineManager.shared
    
    private var monitorTask: Task<Void, Never>?
    
    public init() {
        let completed = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.hasCompletedOnboarding = completed
        self.showOnboardingModal = !completed
        
        if UserDefaults.standard.object(forKey: "moveToTrashOnly") != nil {
            self.moveToTrashOnly = UserDefaults.standard.bool(forKey: "moveToTrashOnly")
        }
        
        refreshSystemStats()
        startMonitoring()
    }
    
    public func relaunchOnboarding() {
        showOnboardingModal = true
    }
    
    deinit {
        monitorTask?.cancel()
    }
    
    // MARK: - Monitoring
    public func refreshSystemStats() {
        self.memoryStats = systemMonitor.fetchMemoryStats()
        self.diskStats = systemMonitor.fetchDiskStats()
    }
    
    private func startMonitoring() {
        monitorTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self?.refreshSystemStats()
            }
        }
    }
    
    // MARK: - Calculations
    public var totalCleanableBytes: Int64 {
        var total: Int64 = 0
        for (_, items) in scannedItemsByCategory {
            total += items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
        }
        return total
    }
    
    public var formattedTotalCleanable: String {
        ByteCountFormatter.string(fromByteCount: totalCleanableBytes, countStyle: .file)
    }
    
    public func categorySize(_ category: JunkCategory) -> Int64 {
        scannedItemsByCategory[category]?.reduce(0) { $0 + $1.size } ?? 0
    }
    
    public func formattedCategorySize(_ category: JunkCategory) -> String {
        ByteCountFormatter.string(fromByteCount: categorySize(category), countStyle: .file)
    }
    
    public func selectedCategoryCount(_ category: JunkCategory) -> Int {
        scannedItemsByCategory[category]?.filter { $0.isSelected }.count ?? 0
    }
    
    // MARK: - Smart Scan
    public func startSmartScan() {
        guard !isScanning else { return }
        isScanning = true
        scannerState = .scanning(progress: 0.05, path: "Initializing Smart Scan...")
        scanProgress = 0.05
        scannedItemsByCategory.removeAll()
        cleanCelebration = false
        
        Task {
            let categoriesToScan: [JunkCategory] = [
                .userCaches,
                .systemFiles,
                .developerJunk,
                .systemLogs,
                .browserCaches,
                .trash
            ]
            
            // Also refresh Time Machine purgeable space
            self.purgeableSpaceBytes = self.timeMachineManager.fetchPurgeableSpace()
            self.timeMachineSnapshots = await self.timeMachineManager.listLocalSnapshots()
            
            let totalSteps = Double(categoriesToScan.count)
            
            for (index, cat) in categoriesToScan.enumerated() {
                let baseProgress = Double(index) / totalSteps
                let items = await junkScanner.scanCategory(cat) { [weak self] subProgress, currentItem in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        let combined = baseProgress + (subProgress / totalSteps)
                        self.scanProgress = combined
                        self.currentScanPath = currentItem
                        self.scannerState = .scanning(progress: combined, path: currentItem)
                    }
                }
                
                scannedItemsByCategory[cat] = items
            }
            
            self.isScanning = false
            let totalBytes = self.totalCleanableBytes
            if totalBytes > 0 {
                self.scannerState = .readyToClean(bytes: totalBytes)
            } else {
                self.scannerState = .completed(bytesFreed: 0)
            }
        }
    }
    
    // MARK: - Scan Time Machine Snapshots
    public func scanTimeMachineSnapshots() {
        self.purgeableSpaceBytes = timeMachineManager.fetchPurgeableSpace()
        Task {
            let snapshots = await timeMachineManager.listLocalSnapshots()
            self.timeMachineSnapshots = snapshots
            self.purgeableSpaceBytes = self.timeMachineManager.fetchPurgeableSpace()
        }
    }
    
    // MARK: - Scan Large Files
    public func scanLargeFilesList() {
        guard !isScanning else { return }
        isScanning = true
        currentScanPath = "Scanning files > 50MB..."
        
        Task {
            let items = await largeFileScanner.scanLargeFiles(minSizeBytes: 50 * 1024 * 1024) { [weak self] progress, path in
                Task { @MainActor [weak self] in
                    self?.scanProgress = progress
                    self?.currentScanPath = path
                }
            }
            self.largeFiles = items
            self.isScanning = false
        }
    }
    
    // MARK: - Scan Installed Applications
    public func scanApplications() {
        guard !isScanning else { return }
        isScanning = true
        currentScanPath = "Discovering installed applications..."
        
        Task {
            let apps = await appScanner.scanInstalledApplications { [weak self] progress, path in
                Task { @MainActor [weak self] in
                    self?.scanProgress = progress
                    self?.currentScanPath = path
                }
            }
            self.installedApps = apps
            if self.selectedApp == nil {
                self.selectedApp = apps.first
            }
            self.isScanning = false
        }
    }
    
    // MARK: - Cleaning
    public func performClean() {
        guard !isCleaning else { return }
        isCleaning = true
        
        // Collect all selected items
        var itemsToClean: [ScannedItem] = []
        for (_, items) in scannedItemsByCategory {
            itemsToClean.append(contentsOf: items.filter { $0.isSelected })
        }
        
        Task {
            let result = await cleanerEngine.cleanItems(itemsToClean, moveToTrash: moveToTrashOnly) { [weak self] progress, name in
                Task { @MainActor [weak self] in
                    self?.scanProgress = progress
                    self?.currentScanPath = "Cleaning \(name)..."
                }
            }
            
            self.isCleaning = false
            self.lastCleanResult = result
            self.scannerState = .completed(bytesFreed: result.bytesFreed)
            self.cleanCelebration = true
            
            // Remove cleaned items from model
            for (cat, items) in self.scannedItemsByCategory {
                self.scannedItemsByCategory[cat] = items.filter { !$0.isSelected }
            }
            
            self.refreshSystemStats()
        }
    }
    
    // MARK: - Item Selection Helpers
    public func toggleItemSelection(category: JunkCategory, id: UUID) {
        guard var items = scannedItemsByCategory[category],
              let idx = items.firstIndex(where: { $0.id == id }) else { return }
        
        items[idx].isSelected.toggle()
        scannedItemsByCategory[category] = items
        
        let total = totalCleanableBytes
        if case .readyToClean = scannerState {
            scannerState = .readyToClean(bytes: total)
        }
    }
    
    public func toggleSelectAll(category: JunkCategory, select: Bool) {
        guard var items = scannedItemsByCategory[category] else { return }
        for i in 0..<items.count {
            items[i].isSelected = select
        }
        scannedItemsByCategory[category] = items
    }
    
    public func toggleLargeFileSelection(id: UUID) {
        guard let idx = largeFiles.firstIndex(where: { $0.id == id }) else { return }
        largeFiles[idx].isSelected.toggle()
    }
    
    // MARK: - RAM Optimization
    public func purgeRAM() {
        guard !isPurgingMemory else { return }
        isPurgingMemory = true
        
        Task {
            _ = await systemMonitor.purgeMemory()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            self.refreshSystemStats()
            self.isPurgingMemory = false
        }
    }
    
    // MARK: - Uninstall Application
    public func uninstallApp(_ app: AppInfo) {
        var itemsToDelete: [ScannedItem] = []
        // App bundle itself
        itemsToDelete.append(
            ScannedItem(
                url: app.bundleURL,
                name: app.name,
                size: app.appBinarySize,
                category: .appLeftovers,
                isSelected: true,
                isSafe: true
            )
        )
        // Associated items
        itemsToDelete.append(contentsOf: app.associatedItems.filter { $0.isSelected })
        
        Task {
            _ = await cleanerEngine.cleanItems(itemsToDelete, moveToTrash: true)
            self.installedApps.removeAll(where: { $0.id == app.id })
            self.selectedApp = self.installedApps.first
            self.refreshSystemStats()
        }
    }
}
