import SwiftUI

@main
struct OllaYMercadoApp: App {
    @State private var state = AppState()

    var body: some Scene {
        WindowGroup {
            TabView {
                TodayView()
                    .tabItem { Label("Hoy", systemImage: "sun.max") }
                WeekView()
                    .tabItem { Label("Semana", systemImage: "calendar") }
                MarketView()
                    .tabItem { Label("Mercado", systemImage: "cart") }
                RecipesView()
                    .tabItem { Label("Recetas", systemImage: "fork.knife") }
            }
            .tint(Theme.herb)
            .environment(state)
        }
    }
}

enum Theme {
    static let herb = Color(light: 0x2E6A4C, dark: 0x6FC196)
    static let maiz = Color(light: 0xE3A12F, dark: 0xF0B550)
    static let maizSoft = Color(light: 0xFBEBCB, dark: 0x3A2E17)
    static let herbSoft = Color(light: 0xDCEBE0, dark: 0x1F3428)
    static let bad = Color(light: 0xB23A2E, dark: 0xF08A7E)
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        func ui(_ hex: UInt32) -> UIColor {
            UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        }
        let l = ui(light), d = ui(dark)
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? d : l })
    }
}

struct Chip: View {
    let text: String
    var fg: Color = .secondary
    var bg: Color = Color(uiColor: .tertiarySystemFill)

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(fg)
            .background(bg, in: Capsule())
    }
}

struct StoreChip: View {
    let store: Store

    var body: some View {
        Chip(text: store.rawValue,
             fg: store == .d1 ? Theme.maiz : Theme.herb,
             bg: store == .d1 ? Theme.maizSoft : Theme.herbSoft)
    }
}

struct MealRow: View {
    let label: String?
    let recipe: Recipe
    let n: Nutrition

    var body: some View {
        HStack(spacing: 12) {
            if let label {
                Text(label.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 74, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name).font(.body.weight(.semibold)).foregroundStyle(.primary)
                Text("\(n.kcal) kcal · \(n.prot) g prot · \(recipe.minutes) min")
                    .font(.caption).monospacedDigit().foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if recipe.batch { Chip(text: "Lote", fg: .white, bg: Theme.herb) }
        }
        .padding(.vertical, 2)
    }
}
