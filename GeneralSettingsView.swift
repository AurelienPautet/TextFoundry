import SwiftUI

struct GeneralSettingsView: View {
    @StateObject private var launchManager = LaunchAtLoginManager()

    var body: some View {
        Form {
            Section {
                if #available(macOS 13.0, *) {
                    Toggle("Launch at Login", isOn: $launchManager.isEnabled)
                } else {
                    Text("Launch at startup requires macOS 13 or newer.")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Startup")
            } footer: {
                Text("Automatically start AI Corrector when you log in.")
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("General Settings")
    }
}

#Preview {
    GeneralSettingsView()
}
