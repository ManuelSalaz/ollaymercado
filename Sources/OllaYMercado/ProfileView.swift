import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var state = state
        let p = state.data.profile
        let t = state.targets
        let imc = p.weight / pow(p.height / 100, 2)

        NavigationStack {
            Form {
                Section("Tus datos") {
                    LabeledContent("Edad") {
                        TextField("Ej. 21", value: $state.data.profile.age, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Peso (kg)") {
                        TextField("60", value: $state.data.profile.weight, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Estatura (cm)") {
                        TextField("170", value: $state.data.profile.height, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    Picker("Sexo", selection: $state.data.profile.sex) {
                        Text("Sin elegir").tag(String?.none)
                        Text("Hombre").tag(String?.some("h"))
                        Text("Mujer").tag(String?.some("m"))
                    }
                }

                Section("Actividad y objetivo") {
                    Picker("Actividad", selection: $state.data.profile.activity) {
                        Text("Poca").tag(1.375)
                        Text("Media (ejercicio 3–4 días)").tag(1.55)
                        Text("Alta").tag(1.725)
                    }
                    Picker("Objetivo", selection: $state.data.profile.goal) {
                        Text("Ganar músculo").tag("ganar")
                        Text("Recomposición").tag("recomp")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Mercado") {
                    LabeledContent("Presupuesto semanal") {
                        TextField("130000", value: $state.data.profile.budget, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }

                Section {
                    HStack(spacing: 16) {
                        Stat(title: "Meta diaria", value: t.kcal.miles, goal: "kcal")
                        Stat(title: "Proteína", value: "\(t.prot)", goal: "g")
                    }
                    Text("IMC \(imc.formatted(.number.precision(.fractionLength(1)))). Gasto en reposo ≈ \(t.bmr.miles) kcal, gasto diario ≈ \(t.tdee.miles) kcal\(t.estimated ? " (estimado: falta edad o sexo)" : "").")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text(p.goal == "ganar"
                         ? "Comes unas 300 kcal por encima de tu gasto: ganas músculo con poca grasa."
                         : "Comes casi lo que gastas: bajas la grasa localizada mientras ganas algo de músculo. Es más lento para los brazos.")
                        .font(.footnote)
                } footer: {
                    Text("Con 60 kg y 170 cm, lo que más te sirve es ganar músculo con un superávit pequeño y 1,8 g de proteína por kilo. La grasa no se quita de una zona específica: se reduce en todo el cuerpo a medida que ganas músculo.")
                }
            }
            .navigationTitle("Mis datos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Listo") { dismiss() }
            }
        }
    }
}
