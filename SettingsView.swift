import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var modelStore: ModelStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !appState.isAccessibilityGranted {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Accessibility Permission Required")
                                .font(.headline)
                            Text("Hotkeys require accessibility access to work.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Grant Access") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                    .padding()
                }
                
                // General Settings
                GeneralSettingsCard()
                
                // Providers
                ProvidersCard()
                    .environmentObject(modelStore)
                
                // Shortcuts
                ShortcutsCard()
            }
            .padding()
        }
        .navigationTitle("Settings")
    }
}

struct GeneralSettingsCard: View {
    @StateObject private var launchManager = LaunchAtLoginManager()
    @AppStorage("retryCount") private var retryCount: Int = 0
    @AppStorage("playSounds") private var playSounds: Bool = true
    @AppStorage("smartPaste") private var smartPaste: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Launch at Login", systemImage: "arrow.up.right.and.arrow.down.left.rectangle")
                    Spacer()
                    if #available(macOS 13.0, *) {
                        Toggle("", isOn: $launchManager.isEnabled)
                    }
                }
                
                Divider()
                
                HStack {
                    Label("Play Sounds", systemImage: "speaker.wave.2")
                    Spacer()
                    Toggle("", isOn: $playSounds)
                }
                
                Divider()
                
                HStack {
                    Label("Smart Paste", systemImage: "doc.on.clipboard")
                    Spacer()
                    Toggle("", isOn: $smartPaste)
                        .help("Pastes text matching the destination style (Option+Shift+Cmd+V)")
                }
                
                Divider()
                
                HStack {
                    Label("Retry Attempts", systemImage: "arrow.clockwise")
                    Spacer()
                    Stepper("\(retryCount)", value: $retryCount, in: 0...5)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct ProvidersCard: View {
    @EnvironmentObject var modelStore: ModelStore
    @AppStorage("lmStudioAddress") private var lmStudioAddress: String = "http://localhost:1234"
    @AppStorage("geminiAPIKey") private var geminiAPIKey: String = ""
    @AppStorage("openAIAPIKey") private var openAIAPIKey: String = ""
    @AppStorage("grokAPIKey") private var grokAPIKey: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("API Providers")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // LM Studio
                VStack(alignment: .leading, spacing: 4) {
                    Text("LM Studio")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    TextField("Server Address", text: $lmStudioAddress)
                        .textFieldStyle(.roundedBorder)
                }
                
                Divider()
                
                // Gemini
                VStack(alignment: .leading, spacing: 4) {
                    Text("Google Gemini")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    SecureField("API Key", text: $geminiAPIKey)
                        .textFieldStyle(.roundedBorder)
                    Link("Get API Key", destination: URL(string: "https://makersuite.google.com/app/apikey")!)
                        .font(.caption2)
                }
                
                Divider()
                
                // OpenAI
                VStack(alignment: .leading, spacing: 4) {
                    Text("OpenAI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    SecureField("API Key", text: $openAIAPIKey)
                        .textFieldStyle(.roundedBorder)
                }
                
                Divider()
                
                // Grok
                VStack(alignment: .leading, spacing: 4) {
                    Text("xAI Grok")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    SecureField("API Key", text: $grokAPIKey)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct ShortcutsCard: View {
    @EnvironmentObject var promptStore: PromptStore
    @EnvironmentObject var shortcutStore: ShortcutStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keyboard Shortcuts")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Main Shortcut")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text("This shortcut runs the prompt currently selected in the menu bar.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ShortcutEditorRow(shortcut: $shortcutStore.mainShortcut)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Action Panel")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text("Opens a floating panel to choose a prompt.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ShortcutEditorRow(shortcut: $shortcutStore.quickActionShortcut)
                }
                
                Divider()
                
                Text("Prompt-Specific Hotkeys")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                ForEach($promptStore.prompts) { $prompt in
                    ShortcutEditorRow(
                        promptName: prompt.name,
                        shortcut: Binding(
                            get: { shortcutStore.shortcut(for: prompt.id) },
                            set: { newShortcut in shortcutStore.updateShortcut(newShortcut) }
                        )
                    )
                    if prompt.id != promptStore.prompts.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(ModelStore())
        .environmentObject(PromptStore())
        .environmentObject(ShortcutStore())
}
