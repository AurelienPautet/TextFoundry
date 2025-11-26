import SwiftUI

struct ProviderSettingsView: View {
    @EnvironmentObject var modelStore: ModelStore
    @AppStorage("lmStudioAddress") private var lmStudioAddress: String = "http://localhost:1234"
    @AppStorage("geminiAPIKey") private var geminiAPIKey: String = ""
    @State private var newModelName: String = ""

    var body: some View {
        Form {
            Section("LM Studio") {
                TextField("Server Address", text: $lmStudioAddress)
                    .textFieldStyle(.roundedBorder)
                Text("Default: http://localhost:1234")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Google Gemini") {
                SecureField("API Key", text: $geminiAPIKey)
                    .textFieldStyle(.roundedBorder)
                Link("Get API Key", destination: URL(string: "https://makersuite.google.com/app/apikey")!)
                    .font(.caption)
                
                Text("Models")
                    .font(.headline)
                
                ForEach(modelStore.models, id: \.self) { model in
                    HStack {
                        Text(model)
                        Spacer()
                        Button(action: { modelStore.deleteModel(named: model) }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                HStack {
                    TextField("Add Model (e.g., gemini-1.5-pro)", text: $newModelName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addModel)
                    
                    Button(action: addModel) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newModelName.isEmpty)
                    .buttonStyle(.borderless)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Provider Settings")
    }
    
    private func addModel() {
        let trimmed = newModelName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            modelStore.addModel(trimmed)
            newModelName = ""
        }
    }
}

#Preview {
    ProviderSettingsView()
}
