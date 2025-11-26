import SwiftUI

struct GeneralSettingsView: View {
    @StateObject private var launchManager = LaunchAtLoginManager()

    var body: some View {
        Form {
            Section("General") {
                if #available(macOS 13.0, *) {
                    Toggle("Launch at startup", isOn: $launchManager.isEnabled)
                } else {
                    Text("Launch at startup requires macOS 13 or newer.")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .navigationTitle("General Settings")
    }
}

#Preview {
    GeneralSettingsView()
}
