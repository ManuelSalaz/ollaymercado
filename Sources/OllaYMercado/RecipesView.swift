import SwiftUI

struct RecipesView: View {
    @Environment(AppState.self) private var state
    @State private var filter = "todas"

    private let filters: [(String, String)] = [
        ("todas", "Todas"), ("des", "Desayunos"), ("plato", "Almuerzo y cena"), ("mer", "Meriendas"), ("lote", "Para lote"),
    ]

    var body: some View {
        let list = Catalog.recipes.filter { r in
            switch filter {
            case "todas": true
            case "lote": r.batch
            default: r.cats.contains { $0.rawValue == filter }
            }
        }

        NavigationStack {
            List {
                Section {
                    Picker("Mostrar", selection: $filter) {
                        ForEach(filters, id: \.0) { Text($0.1).tag($0.0) }
                    }
                } footer: {
                    Text("\(Catalog.recipes.count) recetas, todas en menos de 35 minutos.")
                }
                Section {
                    ForEach(list) { r in
                        NavigationLink(value: r.id) {
                            RecipeRow(recipe: r, n: state.nutrition(r))
                        }
                    }
                }
            }
            .navigationTitle("Recetas")
            .navigationDestination(for: String.self) { id in
                if let r = Catalog.recipeByID[id] { RecipeDetail(recipe: r) }
            }
        }
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    let n: Nutrition

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(recipe.name).font(.headline)
            RecipeChips(recipe: recipe, n: n, perPortion: false)
        }
        .padding(.vertical, 2)
    }
}

struct RecipeChips: View {
    let recipe: Recipe
    let n: Nutrition
    let perPortion: Bool

    var body: some View {
        HStack(spacing: 6) {
            Chip(text: "\(recipe.minutes) min")
            Chip(text: "\(n.kcal) kcal")
            Chip(text: "\(n.prot) g prot", fg: Theme.herb, bg: Theme.herbSoft)
            Chip(text: n.cost.cop + (perPortion ? " porción" : ""), fg: Theme.maiz, bg: Theme.maizSoft)
            if recipe.batch { Chip(text: "Lote", fg: .white, bg: Theme.herb) }
        }
    }
}

struct RecipeDetail: View {
    @Environment(AppState.self) private var state
    let recipe: Recipe

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    RecipeChips(recipe: recipe, n: state.nutrition(recipe), perPortion: true)
                }
            } footer: {
                Text("Cantidades para 1 porción.")
            }
            Section("Ingredientes") {
                ForEach(recipe.ing, id: \.item) { i in
                    if let it = Catalog.items[i.item] {
                        HStack {
                            Text(it.name)
                            Spacer()
                            Text(formatQty(i.qty, it.unit)).foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                }
            }
            Section("Pasos") {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, step in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(i + 1)").font(.subheadline.weight(.heavy)).foregroundStyle(Theme.herb)
                        Text(step)
                    }
                }
            }
            if let tip = recipe.tip {
                Section("Consejo") {
                    Text(tip).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
