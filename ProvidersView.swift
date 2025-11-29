import SwiftUI

struct ProviderSettingsView: View {
    @EnvironmentObject var modelStore: ModelStore
    @AppStorage("lmStudioAddress") private var lmStudioAddress: String = ""
    @AppStorage("geminiAPIKey") private var geminiAPIKey: String = ""
    @AppStorage("openAIAPIKey") private var openAIAPIKey: String = ""
    @AppStorage("grokAPIKey") private var grokAPIKey: String = ""
    
    @State private var newModelName: String = ""
    @State private var newOpenAIModelName: String = ""
    @State private var newGrokModelName: String = ""

    var body: some View {
        Form {
            Section("LM Studio") {
                TextField("Server Address", text: $lmStudioAddress)
                    .textFieldStyle(.roundedBorder)
                Text("e.g. http://localhost:1234")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("OpenAI") {
                SecureField("API Key", text: $openAIAPIKey)
                    .textFieldStyle(.roundedBorder)
                
                if !modelStore.openAIModels.isEmpty {
                    Text("Available Models")
                        .font(.headline)
                        .padding(.top, 4)
                    
                    ForEach(modelStore.openAIModels, id: \.self) { model in
                        Text(model)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("xAI Grok") {
                SecureField("API Key", text: $grokAPIKey)
                    .textFieldStyle(.roundedBorder)
                
                if !modelStore.grokModels.isEmpty {
                    Text("Available Models")
                        .font(.headline)
                        .padding(.top, 4)
                    
                    ForEach(modelStore.grokModels, id: \.self) { model in
                        Text(model)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Google Gemini") {
                SecureField("API Key", text: $geminiAPIKey)
                    .textFieldStyle(.roundedBorder)
                Link("Get API Key", destination: URL(string: "https://makersuite.google.com/app/apikey")!)
                    .font(.caption)
                
                if !modelStore.models.isEmpty {
                    Text("Available Models")
                        .font(.headline)
                        .padding(.top, 4)
                    
                    ForEach(modelStore.models, id: \.self) { model in
                        Text(model)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Provider Settings")
    }
}

#Preview {
    ProviderSettingsView()
}
