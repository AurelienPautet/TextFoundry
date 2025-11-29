import SwiftUI

struct GeneralSettingsView: View {
    @StateObject private var launchManager = LaunchAtLoginManager()
    @AppStorage("retryCount") private var retryCount: Int = 0
    @AppStorage("playSounds") private var playSounds: Bool = true
    @AppStorage("showLoadingOverlay") private var showLoadingOverlay: Bool = true

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
                Text("Automatically start TextFoundry when you log in.")
            }
            
            Section {
                Toggle("Play Sounds", isOn: $playSounds)
                Toggle("Show Loading Overlay", isOn: $showLoadingOverlay)
            } header: {
                Text("Interface & Audio")
            }
            
            Section {
                Stepper("Retry Attempts: \(retryCount)", value: $retryCount, in: 0...5)
                Text("Number of times to retry if the AI request fails.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Reliability")
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
