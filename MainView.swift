import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            List(selection: $appState.selectedPanel) {
                Label("Corrector", systemImage: "text.magnifyingglass")
                    .tag(Panel.corrector)
                
                Label("Master Prompt", systemImage: "star")
                    .tag(Panel.masterPrompt)
                
                Label("Prompts", systemImage: "list.bullet.rectangle")
                    .tag(Panel.prompts)
                
                Label("History", systemImage: "clock")
                    .tag(Panel.history)
                
                Label("Settings", systemImage: "gearshape") // New icon
                    .tag(Panel.settings)
            }
            .navigationSplitViewColumnWidth(220)
        } detail: {
            switch appState.selectedPanel {
            case .corrector:
                CorrectorView()
            case .masterPrompt:
                MasterPromptView()
            case .settings: // Updated to new SettingsView
                SettingsView()
            case .prompts:
                PromptListView()
            case .history:
                HistoryView()
            case .none:
                Text("Select a category")
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(PromptStore())
        .environmentObject(ModelStore())
}
