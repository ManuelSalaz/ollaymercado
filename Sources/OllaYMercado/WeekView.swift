import SwiftUI

struct SwapTarget: Identifiable {
    let day: Int
    let slot: Slot
    var id: String { "\(day)-\(slot.rawValue)" }
}

struct WeekView: View {
    @Environment(AppState.self) private var state
    @State private var day = AppState.todayIndex
    @State private var swap: SwapTarget?
    @State private var confirmReset = false

    var body: some View {
        let tot = state.dayTotal(day)
        let t = state.targets

        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { i in
                                Button {
                                    day = i
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(String(Catalog.days[i].prefix(3))).font(.subheadline.weight(.bold))
                                        Text(String(format: "%.1fk", Double(state.dayTotal(i).kcal) / 1000))
                                            .font(.caption2).monospacedDigit().opacity(0.75)
                                    }
                                    .frame(width: 48, height: 48)
                                    .foregroundStyle(i == day ? Color(uiColor: .systemBackground) : .primary)
                                    .background(i == day ? Color.primary : Color(uiColor: .tertiarySystemFill),
                                                in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .listRowBackground(Color.clear)
                }

                Section {
                    ForEach(Slot.allCases, id: \.self) { s in
                        let r = state.recipe(day: day, slot: s)
                        Button {
                            swap = SwapTarget(day: day, slot: s)
                        } label: {
                            MealRow(label: s.title, recipe: r, n: state.nutrition(r))
                        }
                    }
                } header: {
                    HStack {
                        Text(Catalog.days[day])
                        Spacer()
                        Text("\(tot.kcal) kcal · \(tot.prot) g prot").monospacedDigit()
                    }
                } footer: {
                    Text("Toca una comida para cambiarla. La lista de mercado se ajusta sola. Meta diaria: \(t.kcal.miles) kcal.")
                }

                ForEach(state.batches) { b in
                    Section {
                        if b.portions.isEmpty {
                            Text("Nada de lote. Son platos rápidos.").foregroundStyle(.secondary)
                        }
                        ForEach(b.portions) { p in
                            let r = p.recipe, n = p.count
                            NavigationLink(value: r.id) {
                                HStack {
                                    Text(r.name)
                                    Spacer()
                                    Chip(text: "\(n) porc.")
                                }
                            }
                        }
                    } header: {
                        Text("Cocina en lote: \(b.when)")
                    } footer: {
                        Text("Para \(b.forDays). En nevera dura hasta 4 días; si es para más, congela porciones.")
                    }
                }

                Section {
                    Button("Volver al plan sugerido") { confirmReset = true }
                }
            }
            .navigationTitle("Tu semana")
            .navigationDestination(for: String.self) { id in
                if let r = Catalog.recipeByID[id] { RecipeDetail(recipe: r) }
            }
            .sheet(item: $swap) { target in
                SwapSheet(target: target)
                    .presentationDetents([.medium, .large])
            }
            .confirmationDialog("¿Volver al plan sugerido?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Volver al plan sugerido", role: .destructive) { state.resetPlan() }
            } message: {
                Text("Se reemplazan los cambios que hiciste en la semana.")
            }
        }
    }
}

struct SwapSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let target: SwapTarget

    var body: some View {
        let current = state.recipe(day: target.day, slot: target.slot)
        NavigationStack {
            List {
                Section {
                    ForEach(Catalog.recipes.filter { $0.cats.contains(target.slot.cat) }) { r in
                        Button {
                            state.setRecipe(r.id, day: target.day, slot: target.slot)
                            dismiss()
                        } label: {
                            HStack {
                                let n = state.nutrition(r)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.name).font(.body.weight(.semibold)).foregroundStyle(.primary)
                                    Text("\(r.minutes) min · \(n.kcal) kcal · \(n.prot) g · \(n.cost.cop)")
                                        .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                                }
                                Spacer()
                                if r.id == current.id {
                                    Image(systemName: "checkmark").foregroundStyle(Theme.herb)
                                }
                            }
                        }
                    }
                }
                Section {
                    NavigationLink("Ver la receta actual") { RecipeDetail(recipe: current) }
                }
            }
            .navigationTitle("\(Catalog.days[target.day]) · \(target.slot.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Cerrar") { dismiss() }
            }
        }
    }
}
