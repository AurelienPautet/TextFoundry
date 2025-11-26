import SwiftUI

struct MenuContentView: View {
    // Environment Objects
    @EnvironmentObject var promptStore: PromptStore
    @EnvironmentObject var modelStore: ModelStore
    @EnvironmentObject var shortcutStore: ShortcutStore
    @EnvironmentObject var historyStore: HistoryStore
    @EnvironmentObject var appState: AppState
    
    // Environment Actions
    @Environment(\.openWindow) var openWindow

    // State
    @State private var selectedPromptID: UUID?
    @State private var hotkeyManager: HotkeyManager?

    // Helper to get the selected prompt's name
    private var selectedPromptName: String {
        promptStore.prompts.first(where: { $0.id == selectedPromptID })?.name ?? "Select Prompt"
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

            Text("AI Corrector").font(.headline)
            
            Divider()
            
            Menu {
                Button("Gemini") { appState.selectedAIProvider = "Gemini" }
                Button("LM Studio") { appState.selectedAIProvider = "LM Studio" }
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
                    if modelStore.lmStudioModels.isEmpty {
                        Text("No models found or loading...")
                    } else {
                        ForEach(modelStore.lmStudioModels, id: \.self) { model in
                            Button(model) {
                                appState.selectedLMStudioModel = model
                            }
                        }
                    }
                } label: {
                    Label(appState.selectedLMStudioModel.isEmpty ? "Select Model" : appState.selectedLMStudioModel, systemImage: "cube")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .menuStyle(.borderlessButton)
                .fixedSize(horizontal: false, vertical: true)
            }

            Menu {
                ForEach(promptStore.prompts) { prompt in
                    Button(prompt.name) {
                        selectedPromptID = prompt.id
                    }
                }
            } label: {
                Label(selectedPromptName, systemImage: "text.bubble")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .menuStyle(.borderlessButton)
            .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
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
        let newManager = HotkeyManager(appState: appState, shortcutStore: shortcutStore, promptStore: promptStore, historyStore: historyStore)
        newManager.setupMonitoring()
        self.hotkeyManager = newManager
        
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
