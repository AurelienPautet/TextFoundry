import SwiftUI

struct MenuContentView: View {
    // Environment Objects
    @EnvironmentObject var promptStore: PromptStore
    @EnvironmentObject var modelStore: ModelStore
    @EnvironmentObject var shortcutStore: ShortcutStore
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
            Text("AI Corrector").font(.headline)
            
            Divider()
            
            Menu(selectedPromptName) {
                ForEach(promptStore.prompts) { prompt in
                    Button(prompt.name) {
                        selectedPromptID = prompt.id
                    }
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            
            Divider()
            
            Button("Settings...") {
                openWindow(id: "main-window", value: "main")
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .onAppear(perform: setup)
        .onChange(of: selectedPromptID) {
            UserDefaults.standard.set(selectedPromptID?.uuidString, forKey: "selectedPromptID")
        }
    }
    
    private func setup() {
        let newManager = HotkeyManager(appState: appState, shortcutStore: shortcutStore, promptStore: promptStore)
        newManager.setupMonitoring()
        self.hotkeyManager = newManager
        
        if let promptIDString = UserDefaults.standard.string(forKey: "selectedPromptID"),
           let promptID = UUID(uuidString: promptIDString),
           promptStore.prompts.contains(where: { $0.id == promptID }) {
            selectedPromptID = promptID
        } else {
            selectedPromptID = promptStore.prompts.first?.id
        }
    }
}
