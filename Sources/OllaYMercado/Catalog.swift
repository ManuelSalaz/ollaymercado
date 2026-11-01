import Foundation

enum Store: String, Codable, CaseIterable, Sendable {
    case d1 = "D1"
    case ara = "ARA"
}

struct Item: Sendable {
    let id: String
    let name: String
    let unit: String
    let pkg: Double
    let pkgLabel: String
    let price: Int
    let kcal: Double
    let prot: Double
    let section: String
    let store: Store
    /// true = precio real tomado de la app de ARA; false = estimado (D1 u otra fuente)
    let verified: Bool
}

enum Cat: String, Sendable {
    case des, plato, mer
}

enum Slot: String, CaseIterable, Codable, Sendable {
    case des, alm, mer, cen

    var title: String {
        switch self {
        case .des: "Desayuno"
        case .alm: "Almuerzo"
        case .mer: "Merienda"
        case .cen: "Cena"
        }
    }

    var cat: Cat {
        switch self {
        case .des: .des
        case .alm, .cen: .plato
        case .mer: .mer
        }
    }
}

struct Ing: Sendable {
    let item: String
    let qty: Double
}

struct Recipe: Identifiable, Sendable {
    let id: String
    let name: String
    let cats: [Cat]
    let minutes: Int
    let batch: Bool
    let ing: [Ing]
    let steps: [String]
    let tip: String?
}

enum Catalog {
    static let pricesDate = "29 oct 2026 (app de ARA)"

    static let days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]

    static let sections = ["Fruver", "Carnes", "Enlatados", "Huevos y lácteos", "Despensa", "Panadería", "Congelados"]

    static let basics = ["Sal", "Ajo", "Comino", "Color (achiote)", "Caldo en cubo", "Pimienta", "Sazonador o adobo"]

    private static func it(_ id: String, _ name: String, _ unit: String, _ pkg: Double, _ pkgLabel: String,
                           _ price: Int, _ kcal: Double, _ prot: Double, _ section: String, _ store: Store,
                           _ verified: Bool = true) -> Item {
        Item(id: id, name: name, unit: unit, pkg: pkg, pkgLabel: pkgLabel, price: price, kcal: kcal,
             prot: prot, section: section, store: store, verified: verified)
    }

    // Precios reales de la app de ARA (29 oct 2026). Los de D1 quedan como estimados
    // porque ARA no vende esos productos (lentejas, avena barata, maní, fríjol en lata).
    static let items: [String: Item] = {
        let list: [Item] = [
            it("huevos", "Huevos tipo A (cubeta x30)", "und", 30, "cubeta x30", 14490, 72, 6.3, "Huevos y lácteos", .ara),
            it("leche", "Leche entera Betania", "ml", 900, "bolsa 900 ml", 4450, 0.62, 0.032, "Huevos y lácteos", .ara),
            it("yogur", "Yogurt entero Colfrance", "ml", 1000, "bolsa 1 L", 6990, 0.62, 0.032, "Huevos y lácteos", .ara),
            it("queso", "Quesito Colanta (para arepa)", "g", 250, "bloque 250 g", 8590, 3.0, 0.18, "Huevos y lácteos", .ara),
            it("quesotaj", "Queso doble crema tajado", "g", 400, "bloque 400 g (tajado)", 10500, 3.0, 0.22, "Huevos y lácteos", .ara),
            it("arroz", "Arroz Del Costal", "g", 450, "bolsa 450 g", 1400, 3.6, 0.07, "Despensa", .ara),
            it("lentejas", "Lentejas El Estío (D1)", "g", 500, "bolsa 500 g", 2850, 3.5, 0.24, "Despensa", .d1, false),
            it("avena", "Avena en hojuelas BEM", "g", 400, "bolsa 400 g", 2990, 3.8, 0.13, "Despensa", .ara),
            it("pasta", "Espagueti Puglieri", "g", 400, "paquete 400 g", 2690, 3.6, 0.12, "Despensa", .ara),
            it("mani", "Mantequilla de maní Mash (D1)", "g", 227, "frasco 227 g", 5990, 5.9, 0.25, "Despensa", .d1, false),
            it("manis", "Maní salado Tote", "g", 175, "bolsa 175 g", 6990, 5.9, 0.25, "Despensa", .ara),
            it("aceite", "Aceite vegetal Sonelo", "ml", 900, "botella 900 ml", 8990, 8.8, 0, "Despensa", .ara),
            it("atun", "Atún en agua Van Camp's", "lata", 1, "2 latas de 80 g", 8990, 140, 34, "Enlatados", .ara),
            it("frijolata", "Fríjoles con tocino Cheflisto (D1)", "lata", 1, "lata 320 g", 2400, 400, 19, "Enlatados", .d1, false),
            it("pollo", "Pechuga de pollo", "g", 500, "bandeja 500 g", 8475, 1.2, 0.23, "Carnes", .ara),
            it("cerdo", "Pulpa de cerdo", "g", 500, "bandeja 500 g", 11990, 2.0, 0.18, "Carnes", .ara),
            it("pan", "Pan tajado blanco Amapan", "tajada", 18, "bolsa 450 g (≈18 tajadas)", 3250, 65, 2.3, "Panadería", .ara),
            it("arepas", "Arepas blancas De mi Casa", "und", 5, "paquete 400 g (≈5)", 1590, 160, 3, "Panadería", .ara),
            it("tortillas", "Tortillas de harina Camote", "und", 12, "paquete 360 g (x12)", 5350, 95, 3, "Panadería", .ara),
            it("verduras", "Vegetales mixtos congelados", "g", 500, "bolsa 500 g", 3500, 0.5, 0.025, "Congelados", .ara, false),
            it("platano", "Plátano maduro", "und", 2, "500 g (≈2)", 2450, 300, 3, "Fruver", .ara),
            it("papa", "Papa lavada", "g", 500, "500 g", 2990, 0.77, 0.02, "Fruver", .ara),
            it("tomate", "Tomate chonto", "g", 500, "medio kilo", 3800, 0.18, 0.009, "Fruver", .ara),
            it("cebolla", "Cebolla blanca", "g", 500, "medio kilo", 3200, 0.4, 0.011, "Fruver", .ara),
            it("banano", "Banano", "und", 4, "500 g (≈4)", 2300, 105, 1.3, "Fruver", .ara),
            it("aguacate", "Aguacate Hass", "und", 2, "500 g (≈2)", 5900, 240, 3, "Fruver", .ara),
            it("zanahoria", "Zanahoria", "g", 500, "medio kilo", 2500, 0.4, 0.009, "Fruver", .ara),
            it("limon", "Limón Tahití", "und", 10, "500 g (≈10)", 3500, 15, 0.3, "Fruver", .ara),
        ]
        return Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
    }()

    private static func r(_ id: String, _ name: String, _ cats: [Cat], _ minutes: Int, batch: Bool = false,
                          _ ing: [(String, Double)], _ steps: [String], tip: String? = nil) -> Recipe {
        Recipe(id: id, name: name, cats: cats, minutes: minutes, batch: batch,
               ing: ing.map { Ing(item: $0.0, qty: $0.1) }, steps: steps, tip: tip)
    }

    /// Cantidades por porción. El huevo siempre frito o revuelto, nunca cocido.
    static let recipes: [Recipe] = [
        r("avena", "Avena cremosa con banano y maní", [.des], 5,
          [("avena", 60), ("leche", 250), ("banano", 1), ("mani", 15)],
          ["Pon la avena y la leche en un tazón grande.", "Microondas 2 min, revuelve, 1 min más.", "Encima: banano en rodajas y una cucharada de maní."],
          tip: "Si la dejas lista en la noche en un frasco (sin calentar), en la mañana solo la comes."),
        r("pancakeavena", "Pancakes de avena y banano", [.des], 10,
          [("avena", 60), ("banano", 1), ("huevos", 1), ("leche", 60)],
          ["Licúa la avena, el banano, el huevo y la leche hasta que quede una masa.", "Vierte porciones en una sartén caliente con muy poco aceite.", "Voltea cuando salgan burbujas, 1 min por lado.", "Encima: rodajas de banano o una cucharada de maní."],
          tip: "Desayuno barato que llena y no lleva harina. El huevo solo sirve para unir la masa."),
        r("pericos", "Huevos pericos con arepa", [.des], 10,
          [("huevos", 3), ("tomate", 60), ("cebolla", 30), ("arepas", 2), ("aceite", 5)],
          ["Pica tomate y cebolla pequeño.", "Sofríe 3 min con un chorrito de aceite y sal.", "Agrega los huevos batidos y revuelve hasta que cuajen.", "Calienta las arepas en la misma sartén."],
          tip: "Pica tomate y cebolla para 3 días el domingo y guárdalos en un recipiente."),
        r("sandhuevo", "Sándwich de huevo frito y queso", [.des, .mer], 7,
          [("pan", 2), ("huevos", 2), ("quesotaj", 40)],
          ["Fríe los 2 huevos (o revuélvelos).", "Arma el sándwich con el queso en tajadas.", "Tuéstalo en la sartén 1 min por lado."]),
        r("arepaqueso", "Arepa con queso y vaso de leche", [.des], 6,
          [("arepas", 2), ("queso", 60), ("leche", 250)],
          ["Calienta las arepas en la sartén o el sanduchero, 2 min por lado.", "Ábrelas y mete el queso en tajadas para que se derrita.", "Acompaña con un vaso de leche."]),
        r("sandatun", "Sándwich de atún", [.des, .mer], 5,
          [("pan", 2), ("atun", 1), ("tomate", 40), ("cebolla", 15), ("limon", 0.5)],
          ["Escurre el atún y mézclalo con cebolla picada fina, limón y sal.", "Ponlo en el pan con rodajas de tomate.", "Si quieres, tuéstalo 1 min por lado."],
          tip: "Mucha proteína y no tienes que cocinar nada."),
        r("sandpollo", "Sándwich de pollo y queso", [.des, .mer], 5,
          [("pan", 2), ("pollo", 100), ("quesotaj", 30), ("tomate", 30)],
          ["Usa pollo del lote, desmechado o en tiras.", "Arma el sándwich con queso y tomate.", "Tuéstalo en la sartén 1 min por lado para que el queso se derrita."]),
        r("arepatun", "Arepa rellena de atún", [.des, .mer], 6,
          [("arepas", 1), ("atun", 1), ("tomate", 30), ("limon", 0.5)],
          ["Calienta la arepa y ábrela por la mitad.", "Mezcla el atún escurrido con tomate picado, limón y sal.", "Rellena la arepa."],
          tip: "Merienda alta en proteína sin encender la estufa."),
        r("batido", "Batido ganador", [.mer, .des], 3,
          [("leche", 300), ("avena", 40), ("banano", 1), ("mani", 20)],
          ["Todo a la licuadora 40 segundos.", "Tómalo después del gimnasio o a media tarde."],
          tip: "Son unas 550 kcal en un vaso. Es la forma más fácil de llegar a tus calorías sin cocinar."),
        r("yogurav", "Yogur con avena y banano", [.mer], 2,
          [("yogur", 200), ("avena", 30), ("banano", 1)],
          ["Sirve el yogur, agrega la avena cruda y el banano picado."]),
        r("panmani", "Pan con maní y banano", [.mer], 2,
          [("pan", 2), ("mani", 20), ("banano", 1)],
          ["Unta el maní en el pan y pon el banano en rodajas encima."]),
        r("manifruta", "Maní salado y banano", [.mer], 1,
          [("manis", 40), ("banano", 1)],
          ["Un puñado de maní (unas 3 cucharadas) y un banano. Llévalo en la maleta para la universidad."]),
        r("arrozpollo", "Arroz con pollo y verduras", [.plato], 35, batch: true,
          [("arroz", 110), ("pollo", 150), ("verduras", 80), ("cebolla", 25), ("aceite", 8)],
          ["Corta el pollo en cubos, sal y comino.", "Dóralo en una olla con aceite y cebolla, 6 min.", "Agrega el arroz, color y el doble de agua; tapa a fuego bajo 18 min.", "Los últimos 5 min agrega las verduras congeladas.", "Reparte en recipientes: nevera hasta 4 días."],
          tip: "Hazlo en olla grande para 3 o 4 porciones de una vez. Cocina pollo de más para los wraps y sándwiches."),
        r("pechugaguisada", "Pechuga guisada con papa", [.plato], 30, batch: true,
          [("pollo", 150), ("papa", 300), ("tomate", 60), ("cebolla", 30), ("zanahoria", 40), ("aceite", 5)],
          ["Corta la pechuga en cubos, sal y comino.", "Dórala con aceite, 5 min.", "Agrega tomate, cebolla y zanahoria picados; sofríe 4 min.", "Echa la papa en cubos y agua que cubra; tapa 18 min hasta que la papa ablande.", "Reparte en recipientes: nevera hasta 4 días."],
          tip: "Sírvela con arroz del lote. Queda jugosa y rinde para varios días."),
        r("cerdosudado", "Cerdo sudado con papa", [.plato], 35, batch: true,
          [("cerdo", 150), ("papa", 300), ("tomate", 60), ("cebolla", 30), ("zanahoria", 40), ("aceite", 5)],
          ["Corta el cerdo en cubos, sal y comino.", "Dóralo con aceite, 6 min.", "Agrega tomate, cebolla y zanahoria picados; sofríe 4 min.", "Echa la papa en cubos y agua que cubra; tapa 20 min hasta que todo ablande.", "Reparte en recipientes: nevera hasta 4 días."],
          tip: "Cambia el pollo por cerdo para no comer siempre lo mismo. Sírvelo con arroz del lote."),
        r("lentejas", "Lentejas con arroz y maduro", [.plato], 35, batch: true,
          [("lentejas", 70), ("arroz", 100), ("platano", 0.5), ("zanahoria", 40), ("tomate", 40), ("cebolla", 25), ("aceite", 5)],
          ["Lava las lentejas (no necesitan remojo).", "Hogao: tomate, cebolla, ajo, sal, comino, 5 min.", "Agrega lentejas, zanahoria rallada y 3 veces su volumen de agua; 25 min a fuego medio.", "Mientras tanto, arroz aparte; el maduro al horno o airfryer 15 min."],
          tip: "Lentejas + arroz juntos dan proteína completa, y es de lo más barato del mercado."),
        r("pastaatun", "Pasta con atún y tomate", [.plato], 15,
          [("pasta", 130), ("atun", 1), ("tomate", 80), ("cebolla", 30), ("aceite", 5)],
          ["Cocina la pasta 9 min en agua con sal.", "En una sartén: cebolla y tomate picados 5 min.", "Agrega el atún escurrido y mezcla con la pasta."]),
        r("atunbowl", "Bowl de arroz con atún", [.plato], 8,
          [("arroz", 110), ("atun", 1), ("tomate", 50), ("cebolla", 20), ("aguacate", 0.5), ("limon", 1)],
          ["Calienta el arroz del lote.", "Escurre el atún y mézclalo con tomate y cebolla picados, limón y sal.", "Sírvelo sobre el arroz con el aguacate en tajadas."],
          tip: "Proteína rápida sin cocinar casi nada. Usa el arroz que ya tienes hecho."),
        r("ensaladatun", "Ensalada de atún y aguacate", [.plato, .mer], 7,
          [("atun", 1), ("aguacate", 0.5), ("tomate", 60), ("cebolla", 20), ("limon", 1)],
          ["Escurre el atún.", "Pica tomate, cebolla y aguacate.", "Mezcla todo con limón, sal y un chorrito de aceite."],
          tip: "Cena ligera y llena de proteína para los días que no quieres harina."),
        r("wrapatun", "Wrap de atún y queso", [.plato, .mer], 8,
          [("tortillas", 2), ("atun", 1), ("quesotaj", 30), ("tomate", 40)],
          ["Escurre el atún y mézclalo con sal y limón.", "Calienta las tortillas en la sartén.", "Rellena con atún, queso y tomate. Enrolla."]),
        r("wraps", "Wraps de pollo, queso y aguacate", [.plato], 10,
          [("tortillas", 2), ("pollo", 120), ("quesotaj", 30), ("aguacate", 0.5), ("tomate", 40)],
          ["Saltea el pollo en tiras con sal y ajo, 7 min (o usa el del lote).", "Calienta las tortillas en la sartén.", "Rellena con pollo, queso, aguacate y tomate. Enrolla."]),
        r("bowlpollo", "Bowl de arroz, pollo y aguacate", [.plato], 10,
          [("arroz", 110), ("pollo", 120), ("aguacate", 0.5), ("tomate", 40)],
          ["Calienta el arroz y el pollo del lote.", "Sírvelos en un tazón con aguacate y tomate en tajadas.", "Sal, limón y listo."],
          tip: "Arma la bandeja con lo que cocinaste en lote: cero cocción."),
        r("arrozfrito", "Arroz frito con pollo", [.plato], 10,
          [("arroz", 110), ("pollo", 120), ("verduras", 100), ("aceite", 10)],
          ["Usa arroz ya cocido y pollo del lote.", "Saltea las verduras congeladas 4 min en aceite.", "Agrega el pollo en trocitos y el arroz; revuelve 3 min.", "Sal o salsa de soya."],
          tip: "Ideal para días sin tiempo: es la receta de rescate."),
        r("bowlhuevo", "Bowl de arroz, huevo frito y aguacate", [.plato], 10,
          [("arroz", 110), ("huevos", 2), ("aguacate", 0.5), ("tomate", 40)],
          ["Calienta el arroz del lote.", "Fríe 2 huevos.", "Sirve con aguacate y tomate en tajadas, sal y limón."]),
        r("arrozhuevo", "Arroz frito con huevo revuelto", [.plato], 10,
          [("arroz", 110), ("huevos", 3), ("verduras", 100), ("aceite", 10)],
          ["Usa arroz ya cocido.", "Saltea las verduras congeladas 4 min en aceite.", "Agrega el arroz y empújalo a un lado; revuelve ahí los huevos.", "Mezcla todo; sal o salsa de soya."]),
        r("frijoles", "Fríjoles de lata con arroz y maduro", [.plato], 10,
          [("frijolata", 1), ("arroz", 110), ("platano", 0.5), ("aguacate", 0.25)],
          ["Calienta la lata de fríjoles en una olla pequeña, 4 min.", "Sirve con arroz del lote.", "Maduro en tajadas a la sartén o airfryer y un pedazo de aguacate."],
          tip: "Una bandeja rápida sin remojar fríjoles ni usar olla a presión."),
    ]

    static let recipeByID: [String: Recipe] = Dictionary(uniqueKeysWithValues: recipes.map { ($0.id, $0) })

    static let defaultPlan: [[String: String]] = [
        ["avena", "arrozpollo", "manifruta", "lentejas"],
        ["pericos", "lentejas", "yogurav", "wraps"],
        ["pancakeavena", "arrozpollo", "batido", "pastaatun"],
        ["sandatun", "pechugaguisada", "batido", "bowlpollo"],
        ["pericos", "cerdosudado", "batido", "bowlhuevo"],
        ["arepaqueso", "atunbowl", "arepatun", "frijoles"],
        ["sandhuevo", "wrapatun", "batido", "wraps"],
    ].map { d in
        ["des": d[0], "alm": d[1], "mer": d[2], "cen": d[3]]
    }
}
