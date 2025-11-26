import SwiftUI

struct ProviderSettingsView: View {
    @State private var lmStudioAddress: String = ""
    @State private var geminiAPIKey: String = ""

    var body: some View {
        Form {
            Section("API Endpoints") {
                TextField("LM Studio Address", text: $lmStudioAddress)
                SecureField("Gemini API Key", text: $geminiAPIKey)
            }
        }
        .onAppear {
            lmStudioAddress = UserDefaults.standard.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
            geminiAPIKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        }
        .padding()
        .navigationTitle("Provider Settings") // Updated navigation title
    }
}

#Preview {
    ProviderSettingsView()
}
