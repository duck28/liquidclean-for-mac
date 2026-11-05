import SwiftUI

public struct MetricGaugeView: View {
    let title: String
    let valueText: String
    let subtitle: String
    let percentage: Double
    let gradient: [Color]
    let icon: String
    
    public init(
        title: String,
        valueText: String,
        subtitle: String,
        percentage: Double,
        gradient: [Color],
        icon: String
    ) {
        self.title = title
        self.valueText = valueText
        self.subtitle = subtitle
        self.percentage = percentage
        self.gradient = gradient
        self.icon = icon
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(gradient.first ?? .white)
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(gradient.first ?? .white)
            }
            
            // Progress Bar
            GlassProgressBar(progress: percentage, accentGradient: gradient)
            
            HStack {
                Text(valueText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .liquidGlass(cornerRadius: 18, tintColor: gradient.first)
    }
}
