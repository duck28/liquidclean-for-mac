import SwiftUI
import AppKit

public struct VisualEffectBlur: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

public struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var tintColor: Color?
    var isInteractive: Bool
    @State private var isHovered = false

    public init(cornerRadius: CGFloat = 20, tintColor: Color? = nil, isInteractive: Bool = false) {
        self.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.isInteractive = isInteractive
    }

    public func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Optional subtle tint
                    if let tint = tintColor {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(isHovered ? 0.16 : 0.09))
                    }
                    
                    // Liquid glass specular highlight border
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(isHovered ? 0.45 : 0.28), location: 0.0),
                                    .init(color: .white.opacity(0.10), location: 0.45),
                                    .init(color: (tintColor ?? .white).opacity(0.15), location: 0.75),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: (tintColor ?? .black).opacity(isHovered ? 0.25 : 0.15), radius: isHovered ? 14 : 8, x: 0, y: isHovered ? 6 : 3)
            .scaleEffect(isInteractive && isHovered ? 1.01 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isHovered)
            .onHover { hovering in
                if isInteractive {
                    isHovered = hovering
                }
            }
    }
}

public extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, tintColor: Color? = nil, isInteractive: Bool = false) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, tintColor: tintColor, isInteractive: isInteractive))
    }
}
