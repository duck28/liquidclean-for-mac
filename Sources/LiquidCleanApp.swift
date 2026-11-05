import SwiftUI
import AppKit

@main
struct LiquidCleanApp: App {
    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .preferredColorScheme(.dark)
                .background(WindowAccessor())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1040, height: 700)
    }
}

// Window customizer to enable transparent titlebar and modern vibrancy
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true
                window.backgroundColor = .clear
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
