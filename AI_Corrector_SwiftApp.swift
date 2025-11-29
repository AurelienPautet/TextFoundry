import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    static let shared = AppViewModel() // Singleton for access from AppDelegate/WindowController
    
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

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding5") {
            // Show onboarding window on launch
            DispatchQueue.main.async {
                OnboardingWindowController.shared.show()
            }
        }
    }
}

@main
struct TextFoundryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = AppViewModel.shared

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
                .environmentObject(viewModel) // Pass the entire viewModel
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
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        Group {
            switch appState.status {
            case .ready:
                Image("MenuBarIcon_Ready")
                    .resizable()
            case .busy:
                Image("MenuBarIcon_Busy")
                    .resizable()
            case .error:
                Image("MenuBarIcon_Error")
                    .resizable()
            }
        }
        .aspectRatio(contentMode: .fit)
        .frame(width: 22, height: 22) // Standard menu bar icon size
        .onReceive(NotificationCenter.default.publisher(for: .openMainWindow)) { _ in
            openWindow(id: "main-window", value: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
