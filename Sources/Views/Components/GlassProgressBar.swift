import SwiftUI

public struct GlassProgressBar: View {
    let progress: Double
    let accentGradient: [Color]
    
    @State private var shimmerOffset: CGFloat = -1.0
    
    public init(
        progress: Double,
        accentGradient: [Color] = [Color(red: 0.98, green: 0.25, blue: 0.65), Color(red: 0.35, green: 0.70, blue: 1.0)]
    ) {
        self.progress = progress
        self.accentGradient = accentGradient
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background groove
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    }
                
                // Filled progress
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: accentGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)))
                    .shadow(color: (accentGradient.first ?? .cyan).opacity(0.5), radius: 6)
                    .overlay(alignment: .trailing) {
                        // Shimmer highlight
                        Circle()
                            .fill(.white.opacity(0.8))
                            .frame(width: 8, height: 8)
                            .blur(radius: 2)
                            .padding(.trailing, 2)
                    }
            }
        }
        .frame(height: 10)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
    }
}
