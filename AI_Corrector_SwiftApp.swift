import SwiftUI

@main
struct AI_Corrector_SwiftApp: App {
    // State Objects for the whole app
    @StateObject private var promptStore = PromptStore()
    @StateObject private var modelStore = ModelStore()
    @StateObject private var shortcutStore = ShortcutStore() // Add shortcut store
    @StateObject private var appState = AppState()

    var body: some Scene {
        // The new Menu Bar "scene"
        MenuBarExtra {
            MenuContentView()
                .environmentObject(promptStore)
                .environmentObject(modelStore)
                .environmentObject(shortcutStore) // Inject shortcut store
                .environmentObject(appState)
        } label: {
            MenuBarLabelView(status: appState.status)
        }
        .menuBarExtraStyle(.window) // .window gives a modern, popover-style menu

        // A window for the main UI with sidebar, which can be opened from the menu
        WindowGroup(id: "main-window", for: String.self) { _ in
            MainView()
                .environmentObject(promptStore)
                .environmentObject(modelStore)
                .environmentObject(shortcutStore) // Inject shortcut store
                .environmentObject(appState)
        }
    }
}

// The view for the menu bar icon itself
struct MenuBarLabelView: View {
    let status: AppStatus
    
    var body: some View {
        switch status {
        case .ready:
            Image(systemName: "brain.head.profile")
        case .busy:
            Image(systemName: "hourglass")
        case .error:
            Image(systemName: "exclamationmark.triangle")
        }
    }
}
