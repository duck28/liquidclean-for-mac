import SwiftUI

public enum ScannerState: Equatable {
    case idle
    case scanning(progress: Double, path: String)
    case readyToClean(bytes: Int64)
    case completed(bytesFreed: Int64)
}

public struct LiquidScannerRings: View {
    let state: ScannerState
    let size: CGFloat
    
    @State private var rotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    public init(state: ScannerState, size: CGFloat = 260) {
        self.state = state
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Outer glow ambient circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(0.35), glowColor.opacity(0.05), .clear],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.85
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .scaleEffect(pulseScale)
            
            // Outer dashed orbital ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.05), glowColor.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 10])
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
            
            // Middle fluid gradient ring
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            glowColor,
                            glowColor.opacity(0.1),
                            .white.opacity(0.7),
                            glowColor.opacity(0.3),
                            glowColor
                        ]),
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: size * 0.82, height: size * 0.82)
                .rotationEffect(.degrees(-innerRotation))
                .shadow(color: glowColor.opacity(0.6), radius: 8)
            
            // Inner glowing liquid glass orb
            ZStack {
                // Glass backdrop
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size * 0.62, height: size * 0.62)
                
                // Color gradient fill
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                glowColor.opacity(0.45),
                                glowColor.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.62, height: size * 0.62)
                
                // Rim highlight
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.7), location: 0.0),
                                .init(color: .white.opacity(0.15), location: 0.4),
                                .init(color: glowColor.opacity(0.4), location: 0.8),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: size * 0.62, height: size * 0.62)
                
                // Center icon / graphic
                centerContent
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
                innerRotation = 360
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
        }
    }
    
    @ViewBuilder
    private var centerContent: some View {
        switch state {
        case .idle:
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 0.98, green: 0.35, blue: 0.70)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.98, green: 0.35, blue: 0.70).opacity(0.6), radius: 8)
                
                Text("READY")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
        case .scanning(let progress, _):
            VStack(spacing: 6) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                
                Text("SCANNING")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.8)
                    .foregroundStyle(glowColor)
            }
            
        case .readyToClean(let bytes):
            VStack(spacing: 4) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: size * 0.16, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, glowColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: glowColor.opacity(0.8), radius: 8)
                
                Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
        case .completed:
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.20, green: 0.95, blue: 0.60), Color(red: 0.0, green: 0.75, blue: 0.50)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.20, green: 0.95, blue: 0.60).opacity(0.8), radius: 10)
                
                Text("CLEAN")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white)
            }
        }
    }
    
    private var glowColor: Color {
        switch state {
        case .idle:
            return Color(red: 0.95, green: 0.25, blue: 0.65) // Magenta
        case .scanning:
            return Color(red: 0.0, green: 0.85, blue: 0.95) // Cyan
        case .readyToClean:
            return Color(red: 0.98, green: 0.35, blue: 0.65) // Magenta
        case .completed:
            return Color(red: 0.20, green: 0.90, blue: 0.55) // Emerald
        }
    }
}
