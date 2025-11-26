import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State private var lmStudioAddress: String = ""
    @State private var geminiAPIKey: String = ""

    var body: some View {
        Form {
            Section("API Endpoints") {
                TextField("LM Studio Address", text: $lmStudioAddress)
                SecureField("Gemini API Key", text: $geminiAPIKey)
            }

            HStack {
                Spacer()
                Button("Save") {
                    UserDefaults.standard.set(lmStudioAddress, forKey: "lmStudioAddress")
                    UserDefaults.standard.set(geminiAPIKey, forKey: "geminiAPIKey")
                    print("Settings saved!")
                    dismiss()
                }
                .controlSize(.large)
                Spacer()
            }
        }
        .onAppear {
            lmStudioAddress = UserDefaults.standard.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
            geminiAPIKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        }
        .padding()
        .frame(minWidth: 400, minHeight: 200)
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
