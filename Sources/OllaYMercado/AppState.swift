import Foundation
import Observation

struct Profile: Codable {
    var age: Int?
    var sex: String?          // "h" o "m"
    var height: Double = 170
    var weight: Double = 60
    var activity: Double = 1.55
    var goal: String = "ganar" // "ganar" o "recomp"
    var budget: Int = 130_000
}

struct SavedData: Codable {
    var profile = Profile()
    var plan: [[String: String]] = Catalog.defaultPlan
    var have: Set<String> = []
    var bought: Set<String> = []
    var basics: Set<Int> = []
    var prices: [String: Int] = [:]
    var stores: [String: Store] = [:]
}

struct Nutrition {
    var kcal = 0
    var prot = 0
    var cost = 0
}

struct Targets {
    let kcal: Int
    let prot: Int
    let bmr: Int
    let tdee: Int
    let estimated: Bool
}

struct ShoppingRow: Identifiable {
    let item: Item
    let qty: Double
    let packs: Int
    let cost: Int
    let store: Store
    var id: String { item.id }
}

struct BatchPortion: Identifiable {
    let recipe: Recipe
    let count: Int
    var id: String { recipe.id }
}

struct BatchSession: Identifiable {
    let when: String
    let forDays: String
    let portions: [BatchPortion]
    var id: String { when }
}

@MainActor
@Observable
final class AppState {
    var data: SavedData {
        didSet { save() }
    }

    private static var fileURL: URL {
        URL.documentsDirectory.appending(path: "olla-y-mercado.json")
    }

    init() {
        var loaded = SavedData()
        if let raw = try? Data(contentsOf: Self.fileURL),
           let decoded = try? JSONDecoder().decode(SavedData.self, from: raw) {
            loaded = decoded
        }
        // Si una receta guardada ya no existe, vuelve a la sugerida para ese día
        if loaded.plan.count != 7 { loaded.plan = Catalog.defaultPlan }
        for d in 0..<7 {
            for s in Slot.allCases where Catalog.recipeByID[loaded.plan[d][s.rawValue] ?? ""] == nil {
                loaded.plan[d][s.rawValue] = Catalog.defaultPlan[d][s.rawValue]
            }
        }
        data = loaded
    }

    private func save() {
        if let raw = try? JSONEncoder().encode(data) {
            try? raw.write(to: Self.fileURL, options: .atomic)
        }
    }

    // MARK: - Consultas

    nonisolated static var todayIndex: Int {
        (Calendar.current.component(.weekday, from: .now) + 5) % 7
    }

    func recipe(day: Int, slot: Slot) -> Recipe {
        Catalog.recipeByID[data.plan[day][slot.rawValue] ?? ""] ?? Catalog.recipes[0]
    }

    func setRecipe(_ id: String, day: Int, slot: Slot) {
        data.plan[day][slot.rawValue] = id
    }

    func price(_ id: String) -> Int {
        data.prices[id] ?? Catalog.items[id]?.price ?? 0
    }

    func store(_ id: String) -> Store {
        data.stores[id] ?? Catalog.items[id]?.store ?? .ara
    }

    func nutrition(_ r: Recipe) -> Nutrition {
        var kcal = 0.0, prot = 0.0, cost = 0.0
        for i in r.ing {
            guard let it = Catalog.items[i.item] else { continue }
            kcal += it.kcal * i.qty
            prot += it.prot * i.qty
            cost += Double(price(i.item)) * i.qty / it.pkg
        }
        return Nutrition(kcal: Int(kcal.rounded()), prot: Int(prot.rounded()), cost: Int(cost.rounded()))
    }

    func dayTotal(_ d: Int) -> Nutrition {
        var t = Nutrition()
        for s in Slot.allCases {
            let n = nutrition(recipe(day: d, slot: s))
            t.kcal += n.kcal
            t.prot += n.prot
        }
        return t
    }

    var targets: Targets {
        let p = data.profile
        let age = Double(p.age ?? 21)
        let sx: Double = p.sex == "h" ? 5 : p.sex == "m" ? -161 : -78
        let bmr = 10 * p.weight + 6.25 * p.height - 5 * age + sx
        let tdee = bmr * p.activity
        let kcal = Int(((tdee + (p.goal == "ganar" ? 300 : 100)) / 10).rounded()) * 10
        return Targets(kcal: kcal, prot: Int((p.weight * 1.8).rounded()), bmr: Int(bmr.rounded()),
                       tdee: Int(tdee.rounded()), estimated: p.age == nil || p.sex == nil)
    }

    var shopping: [ShoppingRow] {
        var need: [String: Double] = [:]
        for d in 0..<7 {
            for s in Slot.allCases {
                for i in recipe(day: d, slot: s).ing { need[i.item, default: 0] += i.qty }
            }
        }
        let rows = need.compactMap { id, qty -> ShoppingRow? in
            guard let it = Catalog.items[id] else { return nil }
            let packs = max(1, Int((qty / it.pkg - 1e-9).rounded(.up)))
            return ShoppingRow(item: it, qty: qty, packs: packs, cost: packs * price(id), store: store(id))
        }
        return rows.sorted {
            let a = Catalog.sections.firstIndex(of: $0.item.section) ?? 0
            let b = Catalog.sections.firstIndex(of: $1.item.section) ?? 0
            return a != b ? a < b : $0.item.name < $1.item.name
        }
    }

    var batches: [BatchSession] {
        var s1: [String: Int] = [:], s2: [String: Int] = [:]
        for d in 0..<7 {
            for s in Slot.allCases {
                let r = recipe(day: d, slot: s)
                guard r.batch else { continue }
                if d <= 2 { s1[r.id, default: 0] += 1 } else { s2[r.id, default: 0] += 1 }
            }
        }
        func list(_ m: [String: Int]) -> [BatchPortion] {
            m.compactMap { id, n in Catalog.recipeByID[id].map { BatchPortion(recipe: $0, count: n) } }
                .sorted { $0.recipe.name < $1.recipe.name }
        }
        return [
            BatchSession(when: "Domingo", forDays: "lunes a miércoles", portions: list(s1)),
            BatchSession(when: "Miércoles en la noche", forDays: "jueves a domingo", portions: list(s2)),
        ]
    }

    // MARK: - Acciones

    func toggle(_ set: WritableKeyPath<SavedData, Set<String>>, _ id: String) {
        if data[keyPath: set].contains(id) { data[keyPath: set].remove(id) } else { data[keyPath: set].insert(id) }
    }

    func toggleBasic(_ i: Int) {
        if data.basics.contains(i) { data.basics.remove(i) } else { data.basics.insert(i) }
    }

    func toggleStore(_ id: String) {
        data.stores[id] = store(id) == .d1 ? .ara : .d1
    }

    func newWeek() {
        data.bought = []
        data.have = []
        data.basics = []
    }

    func resetPlan() {
        data.plan = Catalog.defaultPlan
    }
}

// MARK: - Formato

extension Int {
    var cop: String {
        formatted(.currency(code: "COP").locale(Locale(identifier: "es_CO")).precision(.fractionLength(0)))
    }

    var miles: String {
        formatted(.number.locale(Locale(identifier: "es_CO")))
    }
}

func formatQty(_ q: Double, _ unit: String) -> String {
    func short(_ v: Double) -> String {
        v.formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "es_CO")))
    }
    if unit == "g", q >= 1000 { return short(q / 1000) + " kg" }
    if unit == "ml", q >= 1000 { return short(q / 1000) + " L" }
    let one = abs(q - 1) < 0.01
    switch unit {
    case "lata": return short(q) + (one ? " lata" : " latas")
    case "tajada": return short(q) + (one ? " tajada" : " tajadas")
    default: return short(q) + " " + unit
    }
}
