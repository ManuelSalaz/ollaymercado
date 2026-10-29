import SwiftUI

struct MarketView: View {
    @Environment(AppState.self) private var state
    @State private var filter: Store?
    @State private var editing: Item?
    @State private var confirmNewWeek = false

    var body: some View {
        let rows = state.shopping
        let visible = rows.filter { filter == nil || $0.store == filter }
        let toBuy = visible.filter { !state.data.have.contains($0.id) }
        let cost = toBuy.reduce(0) { $0 + $1.cost }
        let inCart = toBuy.filter { state.data.bought.contains($0.id) }.count
        let all = rows.filter { !state.data.have.contains($0.id) }.reduce(0) { $0 + $1.cost }
        let budget = state.data.profile.budget

        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(filter.map { "En \($0.rawValue)" } ?? "Total estimado")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(cost.cop).font(.title.weight(.heavy)).monospacedDigit()
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(inCart)/\(toBuy.count)").font(.title3.weight(.heavy)).monospacedDigit()
                                Text("en el carrito").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        if filter == nil {
                            ProgressView(value: min(Double(all) / Double(max(budget, 1)), 1))
                                .tint(all > budget ? Theme.bad : Theme.maiz)
                            Text("Presupuesto \(budget.cop)" + (all > budget ? " · te pasas \((all - budget).cop)" : ""))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Picker("Tienda", selection: $filter) {
                        Text("Todo").tag(Store?.none)
                        ForEach(Store.allCases, id: \.self) { Text($0.rawValue).tag(Store?.some($0)) }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text("Marca lo que ya tienes en casa antes de salir, y chulea lo que vas echando al carrito.")
                }

                ForEach(Catalog.sections, id: \.self) { sec in
                    let list = visible.filter { $0.item.section == sec }
                    if !list.isEmpty {
                        Section(sec) {
                            ForEach(list) { row in
                                ShoppingRowView(row: row, onPrice: { editing = row.item })
                            }
                        }
                    }
                }

                Section {
                    ForEach(Array(Catalog.basics.enumerated()), id: \.offset) { i, name in
                        let on = state.data.basics.contains(i)
                        Button {
                            state.toggleBasic(i)
                        } label: {
                            HStack(spacing: 12) {
                                CheckBox(on: on)
                                Text(name).strikethrough(on).foregroundStyle(on ? .secondary : .primary)
                            }
                        }
                    }
                } header: {
                    Text("Básicos de cocina")
                } footer: {
                    Text("No se cuentan en el total. Revisa si te falta alguno.")
                }

                Section {
                    Button("Empezar semana nueva", role: .destructive) { confirmNewWeek = true }
                } footer: {
                    Text("Precios tomados de losprecios.co el \(Catalog.pricesDate). Es un sitio donde los usuarios reportan precios, así que algunos pueden estar viejos o variar según tu ciudad. Toca un precio para poner el que viste en la tienda; la app lo recuerda.")
                }
            }
            .navigationTitle("Mercado")
            .sheet(item: $editing) { item in
                PriceSheet(item: item)
                    .presentationDetents([.medium])
            }
            .confirmationDialog("¿Empezar semana nueva?", isPresented: $confirmNewWeek, titleVisibility: .visible) {
                Button("Borrar los chulos", role: .destructive) { state.newWeek() }
            } message: {
                Text("Se desmarca lo que tenías en el carrito y en casa. Tus precios y tu plan se quedan.")
            }
        }
    }
}

extension Item: Identifiable {}

struct CheckBox: View {
    let on: Bool

    var body: some View {
        Image(systemName: on ? "checkmark.square.fill" : "square")
            .font(.title2)
            .foregroundStyle(on ? Theme.herb : .secondary)
    }
}

struct ShoppingRowView: View {
    @Environment(AppState.self) private var state
    let row: ShoppingRow
    let onPrice: () -> Void

    var body: some View {
        let have = state.data.have.contains(row.id)
        let bought = state.data.bought.contains(row.id)
        let note = state.data.prices[row.id] != nil ? " · tu precio" : row.item.verified ? "" : " · precio estimado"

        HStack(alignment: .top, spacing: 12) {
            Button {
                state.toggle(\.bought, row.id)
            } label: {
                CheckBox(on: bought)
            }
            .buttonStyle(.plain)
            .disabled(have)
            .opacity(have ? 0.35 : 1)
            .accessibilityLabel("En el carrito: \(row.item.name)")

            VStack(alignment: .leading, spacing: 4) {
                Text("\(row.packs) × \(row.item.name)")
                    .font(.body.weight(.semibold))
                    .strikethrough(bought || have)
                    .foregroundStyle(bought || have ? .secondary : .primary)
                Text("\(row.item.pkgLabel) · necesitas \(formatQty(row.qty, row.item.unit))\(note)")
                    .font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Button { state.toggleStore(row.id) } label: { StoreChip(store: row.store) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Cambiar tienda")
                    Button { state.toggle(\.have, row.id) } label: {
                        Chip(text: have ? "Ya lo tengo ✓" : "¿Ya lo tienes?")
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
            Button(action: onPrice) {
                Text(have ? "—" : row.cost.cop)
                    .font(.subheadline.weight(.bold)).monospacedDigit()
                    .foregroundStyle(have ? .secondary : .primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Editar precio")
        }
        .padding(.vertical, 2)
    }
}

struct PriceSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let item: Item
    @State private var value: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Precio", value: $value, format: .number)
                        .keyboardType(.numberPad)
                        .font(.title2.weight(.bold))
                } header: {
                    Text("Precio de \(item.pkgLabel) en COP")
                }
                Section {
                    Button("Volver al precio de la página (\(item.price.cop))") {
                        state.data.prices[item.id] = nil
                        dismiss()
                    }
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if let value, value > 0 { state.data.prices[item.id] = value }
                        dismiss()
                    }
                }
            }
            .onAppear { value = state.price(item.id) }
        }
    }
}
