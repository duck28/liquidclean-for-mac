import SwiftUI

public struct LiquidBackgroundView: View {
    @State private var animate = false
    
    public init() {}
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let offset1 = sin(time * 0.4) * 80
            let offset2 = cos(time * 0.35) * 70
            let offset3 = sin(time * 0.25 + 2.0) * 90
            let offset4 = cos(time * 0.3 + 1.0) * 80
            
            ZStack {
                // Deep dark space void background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.04, blue: 0.09),
                        Color(red: 0.08, green: 0.07, blue: 0.14),
                        Color(red: 0.03, green: 0.03, blue: 0.07)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Fluid Blob 1 - Electric Magenta
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.98, green: 0.16, blue: 0.58).opacity(0.40),
                                Color(red: 0.85, green: 0.10, blue: 0.45).opacity(0.15),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 280
                        )
                    )
                    .frame(width: 560, height: 560)
                    .offset(x: -160 + offset1, y: -120 + offset2)
                    .blur(radius: 70)
                
                // Fluid Blob 2 - Royal Violet / Indigo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.45, green: 0.20, blue: 0.95).opacity(0.42),
                                Color(red: 0.30, green: 0.15, blue: 0.80).opacity(0.12),
                                .clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 300
                        )
                    )
                    .frame(width: 600, height: 600)
                    .offset(x: 220 + offset2, y: 140 + offset1)
                    .blur(radius: 80)
                
                // Fluid Blob 3 - Cyan Aqua Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.0, green: 0.85, blue: 0.90).opacity(0.30),
                                Color(red: 0.1, green: 0.60, blue: 0.80).opacity(0.08),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 240
                        )
                    )
                    .frame(width: 480, height: 480)
                    .offset(x: 180 + offset3, y: -180 + offset4)
                    .blur(radius: 65)
                
                // Fluid Blob 4 - Warm Amber / Coral Pulse
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.45, blue: 0.25).opacity(0.24),
                                .clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: -240 + offset4, y: 220 + offset3)
                    .blur(radius: 75)
                
                // Glass noise texture / sheen overlay
                Color.white.opacity(0.015)
                    .blendMode(.overlay)
            }
        }
        .ignoresSafeArea()
    }
}
