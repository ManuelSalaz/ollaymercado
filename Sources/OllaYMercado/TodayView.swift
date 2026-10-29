import SwiftUI

struct TodayView: View {
    @Environment(AppState.self) private var state
    @State private var showProfile = false

    var body: some View {
        let d = AppState.todayIndex
        let t = state.targets
        let tot = state.dayTotal(d)
        let cook: BatchSession? = d == 6 ? state.batches[0] : d == 2 ? state.batches[1] : nil

        NavigationStack {
            List {
                if t.estimated {
                    Section {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Completa tu edad y sexo").font(.headline)
                                Text("Con eso las calorías quedan exactas. Por ahora es un estimado.")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Button("Completar") { showProfile = true }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                    .listRowBackground(Theme.maizSoft)
                }

                Section {
                    HStack(spacing: 16) {
                        Stat(title: "Calorías", value: tot.kcal.miles, goal: "/ \(t.kcal.miles)",
                             progress: Double(tot.kcal) / Double(t.kcal), color: Theme.maiz)
                        Stat(title: "Proteína", value: "\(tot.prot) g", goal: "/ \(t.prot) g",
                             progress: Double(tot.prot) / Double(t.prot), color: Theme.herb)
                    }
                    .padding(.vertical, 4)
                    Text(tot.kcal < t.kcal - 200
                         ? "Te faltan unas \(((t.kcal - tot.kcal) / 10) * 10) kcal: agrega un batido ganador o una porción más de arroz."
                         : "El plan de hoy cubre tu meta. Si te llenas mucho, reparte en 5 comidas.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Comidas") {
                    ForEach(Slot.allCases, id: \.self) { s in
                        let r = state.recipe(day: d, slot: s)
                        NavigationLink(value: r.id) {
                            MealRow(label: s.title, recipe: r, n: state.nutrition(r))
                        }
                    }
                }

                if let cook {
                    Section {
                        if cook.portions.isEmpty {
                            Text("Esta parte de la semana no tiene platos de lote.").foregroundStyle(.secondary)
                        }
                        ForEach(cook.portions) { p in
                            let r = p.recipe, n = p.count
                            NavigationLink(value: r.id) {
                                HStack {
                                    Text(r.name)
                                    Spacer()
                                    Chip(text: "\(n) porciones")
                                }
                            }
                        }
                    } header: {
                        Text("Hoy cocinas en lote")
                    } footer: {
                        Text("Para \(cook.forDays). Cocinas una vez y solo calientas.")
                    }
                }
            }
            .navigationTitle(Catalog.days[d])
            .navigationDestination(for: String.self) { id in
                if let r = Catalog.recipeByID[id] { RecipeDetail(recipe: r) }
            }
            .toolbar {
                Button("Mis datos") { showProfile = true }
            }
            .sheet(isPresented: $showProfile) { ProfileView() }
        }
    }
}

struct Stat: View {
    let title: String
    let value: String
    let goal: String
    var progress: Double? = nil
    var color: Color = .clear

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(.title2.weight(.heavy)).monospacedDigit()
                Text(goal).font(.caption.weight(.semibold)).foregroundStyle(.secondary).monospacedDigit()
            }
            if let progress {
                ProgressView(value: min(max(progress, 0), 1)).tint(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
