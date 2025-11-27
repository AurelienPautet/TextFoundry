import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var isReady = true // Dummy property to satisfy ObservableObject
    let promptStore = PromptStore()
    let modelStore = ModelStore()
    let shortcutStore = ShortcutStore()
    let historyStore = HistoryStore()
    let customPromptHistoryStore = CustomPromptHistoryStore()
    let appState = AppState()
    
    var hotkeyManager: HotkeyManager?
    
    init() {
        self.hotkeyManager = HotkeyManager(
            appState: appState, 
            shortcutStore: shortcutStore, 
            promptStore: promptStore, 
            historyStore: historyStore,
            customPromptHistoryStore: customPromptHistoryStore
        )
        self.hotkeyManager?.setupMonitoring()
    }
}

@main
struct AI_Corrector_SwiftApp: App {
    // State Objects for the whole app
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        // The new Menu Bar "scene"
        MenuBarExtra {
            MenuContentView()
                .environmentObject(viewModel.promptStore)
                .environmentObject(viewModel.customPromptHistoryStore)
                .environmentObject(viewModel.modelStore)
                .environmentObject(viewModel.shortcutStore)
                .environmentObject(viewModel.historyStore)
                .environmentObject(viewModel.appState)
                .onAppear {
                    SoundManager.shared.preloadSounds()
                }
        } label: {
            MenuBarLabelView(appState: viewModel.appState)
        }
        .menuBarExtraStyle(.window) // .window gives a modern, popover-style menu

        // A window for the main UI with sidebar, which can be opened from the menu
        WindowGroup(id: "main-window", for: String.self) { _ in
            MainView()
                .environmentObject(viewModel.promptStore)
                .environmentObject(viewModel.modelStore)
                .environmentObject(viewModel.shortcutStore)
                .environmentObject(viewModel.historyStore)
                .environmentObject(viewModel.customPromptHistoryStore)
                .environmentObject(viewModel.appState)
                .task {
                    // Refresh models on startup
                    let defaults = UserDefaults.standard
                    let geminiKey = defaults.string(forKey: "geminiAPIKey") ?? ""
                    let openAIKey = defaults.string(forKey: "openAIAPIKey") ?? ""
                    let grokKey = defaults.string(forKey: "grokAPIKey") ?? ""
                    
                    await viewModel.modelStore.refreshAllModels(geminiKey: geminiKey, openAIKey: openAIKey, grokKey: grokKey)
                }
        }
    }
}

// The view for the menu bar icon itself
struct MenuBarLabelView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        Group {
            switch appState.status {
            case .ready:
                Image("MenuBarIcon_Ready")
            case .busy:
                Image("MenuBarIcon_Busy")
            case .error:
                Image("MenuBarIcon_Error")
            }
        }
    }
}
