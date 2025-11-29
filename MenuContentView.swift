import SwiftUI

extension Optional where Wrapped == String {
    var isEmptyOrNil: Bool {
        return self?.isEmpty ?? true
    }
}

struct MenuContentView: View {
    // Environment Objects
    @EnvironmentObject var promptStore: PromptStore
    @EnvironmentObject var customPromptStore: CustomPromptHistoryStore
    @EnvironmentObject var modelStore: ModelStore
    @EnvironmentObject var shortcutStore: ShortcutStore
    @EnvironmentObject var historyStore: HistoryStore
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appViewModel: AppViewModel // New AppViewModel environment object
    
    // Environment Actions
    @Environment(\.openWindow) var openWindow

    // State
    @State private var selectedPromptID: UUID?

    // Helper to get the selected prompt's name
    private var selectedPromptName: String {
        if let prompt = promptStore.prompts.first(where: { $0.id == selectedPromptID }) {
            return prompt.name
        } else if let custom = customPromptStore.history.first(where: { $0.id == selectedPromptID }) {
            return "Custom: \(custom.content.prefix(15))..."
        }
        return "Select Prompt"
    }

    var body: some View {
        VStack(spacing: 12) {
            if !appState.isAccessibilityGranted {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text("Accessibility Access Needed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 4)
            }

            Text("TextFoundry").font(.headline)
            
            Divider()
            
            Menu {
                if !UserDefaults.standard.string(forKey: "geminiAPIKey").isEmptyOrNil {
                    Button("Gemini") { appState.selectedAIProvider = "Gemini" }
                }
                Button("LM Studio") { appState.selectedAIProvider = "LM Studio" }
                if !UserDefaults.standard.string(forKey: "openAIAPIKey").isEmptyOrNil {
                    Button("OpenAI") { appState.selectedAIProvider = "OpenAI" }
                }
                if !UserDefaults.standard.string(forKey: "grokAPIKey").isEmptyOrNil {
                    Button("xAI Grok") { appState.selectedAIProvider = "xAI Grok" }
                }
            } label: {
                Label(appState.selectedAIProvider, systemImage: "cpu")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .menuStyle(.borderlessButton)
            .fixedSize(horizontal: false, vertical: true)

            if appState.selectedAIProvider == "Gemini" {
                Menu {
                    ForEach(modelStore.models, id: \.self) { model in
                        Button(model) {
                            appState.selectedGeminiModel = model
                        }
                    }
                } label: {
                    Label(appState.selectedGeminiModel.isEmpty ? "Select Model" : appState.selectedGeminiModel, systemImage: "cube")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .menuStyle(.borderlessButton)
                .fixedSize(horizontal: false, vertical: true)
            } else if appState.selectedAIProvider == "LM Studio" {
                Menu {
                    if !modelStore.lmStudioModels.isEmpty {
                        ForEach(modelStore.lmStudioModels, id: \.self) { model in
                            Button(model) { appState.selectedLMStudioModel = model }
                        }
                    } else {
                        Text("No models found")
                    }
                } label: {
                    Label(appState.selectedLMStudioModel.isEmpty ? "Select Model" : appState.selectedLMStudioModel, systemImage: "cube")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .menuStyle(.borderlessButton)
                .fixedSize(horizontal: false, vertical: true)
            } else if appState.selectedAIProvider == "OpenAI" {
                Menu {
                    ForEach(modelStore.openAIModels, id: \.self) { model in
                        Button(model) { appState.selectedOpenAIModel = model }
                    }
                } label: {
                    Label(appState.selectedOpenAIModel.isEmpty ? "Select Model" : appState.selectedOpenAIModel, systemImage: "cube")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .menuStyle(.borderlessButton)
                .fixedSize(horizontal: false, vertical: true)
            } else if appState.selectedAIProvider == "xAI Grok" {
                Menu {
                    ForEach(modelStore.grokModels, id: \.self) { model in
                        Button(model) { appState.selectedGrokModel = model }
                    }
                } label: {
                    Label(appState.selectedGrokModel.isEmpty ? "Select Model" : appState.selectedGrokModel, systemImage: "cube")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .menuStyle(.borderlessButton)
                .fixedSize(horizontal: false, vertical: true)
            }

            Menu {
                if !customPromptStore.history.isEmpty {
                    Section("Recent Custom Prompts") {
                        ForEach(customPromptStore.history.prefix(2)) { item in
                            Button(action: {
                                selectedPromptID = item.id
                            }) {
                                Text(item.content).lineLimit(1)
                            }
                        }
                    }
                    Divider()
                }
                
                Section("Saved Prompts") {
                    ForEach(promptStore.prompts) { prompt in
                        Button(prompt.name) {
                            selectedPromptID = prompt.id
                        }
                    }
                }
            } label: {
                Label(selectedPromptName, systemImage: "text.bubble")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .menuStyle(.borderlessButton)
            .fixedSize(horizontal: false, vertical: true)
            
            if let stats = appState.lastRunStats {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Run Stats")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(String(format: "%.2fs", stats.duration), systemImage: "stopwatch")
                        Spacer()
                        if let tps = stats.tokensPerSecond {
                            Label(String(format: "%.1f t/s", tps), systemImage: "speedometer")
                        }
                    }
                    .font(.caption2)
                    
                    if let ttft = stats.timeToFirstToken {
                        HStack {
                            Label(String(format: "TTFT: %.2fs", ttft), systemImage: "bolt")
                            Spacer()
                            if let retries = stats.retryCount, retries > 0 {
                                Label("\(retries) retry", systemImage: "arrow.clockwise")
                                    .foregroundColor(.orange)
                            }
                        }
                        .font(.caption2)
                    }
                }
                .padding(.vertical, 4)
            }
            
            if case .error(let message) = appState.status {
                Divider()
                Text(message)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 4)
            }
            
            Divider()
            
            Button(action: {
                guard let promptID = selectedPromptID else { return }
                Task {
                    await appViewModel.hotkeyManager?.correctClipboard(promptID: promptID)
                }
            }) {
                Label("Correct Clipboard", systemImage: "doc.on.clipboard")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .disabled(selectedPromptID == nil)
            
            Button(action: {
                NSApplication.shared.activate(ignoringOtherApps: true)
                appState.selectedPanel = .settings
                openWindow(id: "main-window", value: "main")
            }) {
                Label("Settings...", systemImage: "gear")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .frame(width: 200)
        .onAppear(perform: setup)
        .onChange(of: selectedPromptID) {
            UserDefaults.standard.set(selectedPromptID?.uuidString, forKey: "selectedPromptID")
        }
    }
    
    private func setup() {
        // Fetch LM Studio models on startup
        let lmStudioAddress = UserDefaults.standard.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
        Task {
            await modelStore.fetchLMStudioModels(from: lmStudioAddress)
        }
        
        if let promptIDString = UserDefaults.standard.string(forKey: "selectedPromptID"),
           let promptID = UUID(uuidString: promptIDString),
           promptStore.prompts.contains(where: { $0.id == promptID }) {
            selectedPromptID = promptID
        } else {
            selectedPromptID = promptStore.prompts.first?.id
        }
    }
}

#Preview {
    MenuContentView()
        .environmentObject(PromptStore())
        .environmentObject(CustomPromptHistoryStore())
        .environmentObject(ModelStore())
        .environmentObject(ShortcutStore())
        .environmentObject(HistoryStore())
        .environmentObject(AppState())
        .environmentObject(AppViewModel())
}
