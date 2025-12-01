import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            List(selection: $appState.selectedPanel) {
                Label("Foundry", image: "MenuBarIcon_Busy")
                    .tag(Panel.corrector)
                
                Label("Prompts", systemImage: "list.bullet.rectangle")
                    .tag(Panel.prompts)
                
                Label("Custom Prompts", systemImage: "wand.and.stars")
                    .tag(Panel.customPrompts)
                
                Label("History", systemImage: "clock")
                    .tag(Panel.history)
                
                Label("Stats", systemImage: "chart.bar.xaxis")
                    .tag(Panel.stats)
                
                Label("Settings", systemImage: "gearshape") // New icon
                    .tag(Panel.settings)
            }
            .navigationSplitViewColumnWidth(220)
        } detail: {
            switch appState.selectedPanel {
            case .corrector:
                CorrectorView()
            case .settings: // Updated to new SettingsView
                SettingsView()
            case .prompts:
                PromptListView()
            case .customPrompts:
                CustomPromptsView()
            case .history:
                HistoryView()
            case .stats:
                StatsView()
            case .masterPrompt:
                PromptListView()
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
