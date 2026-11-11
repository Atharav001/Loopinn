import SwiftUI

enum LoopinnDesign {
    static let sidebarWidth: CGFloat = 250
    static let cardRadius: CGFloat = 18
    static let panelRadius: CGFloat = 18
    static let contentSpacing: CGFloat = 24
}

struct LoopinnCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: LoopinnDesign.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LoopinnDesign.cardRadius)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
            }
    }
}

struct SectionHeading: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.weight(.semibold))
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
        }
    }
}

enum TaskAppearance {
    static func color(for tag: String?) -> Color {
        switch tag {
        case "Blue": .blue
        case "Teal": .teal
        case "Orange": .orange
        case "Purple": .purple
        default: .clear
        }
    }
}
