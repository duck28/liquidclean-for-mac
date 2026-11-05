import SwiftUI

public struct GlassButton: View {
    public enum Style {
        case primary(colors: [Color])
        case secondary
        case destructive
    }
    
    let title: String
    let icon: String?
    let style: Style
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    public init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary(colors: [Color(red: 0.98, green: 0.25, blue: 0.65), Color(red: 0.55, green: 0.15, blue: 0.95)]),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background {
                backgroundContent
            }
            .clipShape(Capsule())
            .overlay {
                // Specular top highlight
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.55), location: 0.0),
                                .init(color: .white.opacity(0.12), location: 0.5),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: shadowColor, radius: isHovered ? 12 : 6, x: 0, y: isHovered ? 5 : 2)
            .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.03 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        ._onButtonGesture { pressing in
            isPressed = pressing
        } perform: {}
    }
    
    @ViewBuilder
    private var backgroundContent: some View {
        switch style {
        case .primary(let colors):
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(isHovered ? 1.0 : 0.9)
            
        case .secondary:
            Color.white.opacity(isHovered ? 0.18 : 0.10)
            
        case .destructive:
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.25, blue: 0.30), Color(red: 0.75, green: 0.10, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(isHovered ? 1.0 : 0.9)
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary(let colors):
            return (colors.first ?? .purple).opacity(isHovered ? 0.45 : 0.25)
        case .secondary:
            return Color.black.opacity(0.2)
        case .destructive:
            return Color(red: 0.95, green: 0.25, blue: 0.30).opacity(isHovered ? 0.5 : 0.25)
        }
    }
}
