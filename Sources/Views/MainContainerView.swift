import SwiftUI

public struct MainContainerView: View {
    @StateObject private var viewModel = AppViewModel()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Ambient Living Liquid Wallpaper
            LiquidBackgroundView()
            
            // App Layout Split
            HStack(spacing: 0) {
                // Frosted Glass Sidebar
                SidebarView(viewModel: viewModel)
                
                // Active Content Workspace
                ZStack {
                    switch viewModel.selectedTab {
                    case .smartScan:
                        SmartScanView(viewModel: viewModel)
                    case .systemJunk:
                        SystemJunkView(viewModel: viewModel)
                    case .timeMachine:
                        TimeMachineView(viewModel: viewModel)
                    case .developerJunk:
                        DeveloperJunkView(viewModel: viewModel)
                    case .largeFiles:
                        LargeFilesView(viewModel: viewModel)
                    case .uninstaller:
                        UninstallerView(viewModel: viewModel)
                    case .systemPerformance:
                        SystemPerformanceView(viewModel: viewModel)
                    case .settings:
                        SettingsView(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            
            // First-launch Onboarding & Setup Experience
            if viewModel.showOnboardingModal {
                OnboardingView(viewModel: viewModel, isPresented: $viewModel.showOnboardingModal)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(100)
            }
        }
        .frame(minWidth: 980, minHeight: 650)
    }
}
