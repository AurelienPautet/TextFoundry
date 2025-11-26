import SwiftUI

struct MainView: View {
    @State private var selection: Panel? = .corrector // Default to corrector

    enum Panel: Hashable {
        case corrector
        case masterPrompt
        case settings // Renamed from providers
        case prompts
        case models
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Corrector", systemImage: "text.magnifyingglass")
                    .tag(Panel.corrector)
                
                Label("Master Prompt", systemImage: "star")
                    .tag(Panel.masterPrompt)
                
                Label("Settings", systemImage: "gearshape") // New icon
                    .tag(Panel.settings)

                Label("Prompts", systemImage: "list.bullet.rectangle")
                    .tag(Panel.prompts)
                
                Label("Models", systemImage: "brain.head.profile")
                    .tag(Panel.models)
            }
            .navigationSplitViewColumnWidth(220)
        } detail: {
            switch selection {
            case .corrector:
                CorrectorView()
            case .masterPrompt:
                MasterPromptView()
            case .settings: // Updated to new SettingsView
                SettingsView()
            case .prompts:
                PromptListView()
            case .models:
                ModelListView()
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
