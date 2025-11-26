import SwiftUI

struct SettingsView: View {
    enum TabSelection: String, CaseIterable, Identifiable {
        case general = "General" // New General tab
        case providers = "Providers"
        case shortcuts = "Shortcuts"
        
        var id: String { self.rawValue }
    }
    
    @State private var selectedTab: TabSelection = .general // Default to General tab

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView() // Add the new General Settings view
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(TabSelection.general)
            
            ProviderSettingsView()
                .tabItem { Label("Providers", systemImage: "network") }
                .tag(TabSelection.providers)
            
            ShortcutSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                .tag(TabSelection.shortcuts)
        }
        .frame(minWidth: 500, minHeight: 300)
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
