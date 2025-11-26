import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState // Add appState
    @EnvironmentObject var modelStore: ModelStore // Add environment object
    
    enum TabSelection: String, CaseIterable, Identifiable {
        case general = "General" // New General tab
        case providers = "Providers"
        case shortcuts = "Shortcuts"
        
        var id: String { self.rawValue }
    }
    
    @State private var selectedTab: TabSelection = .general // Default to General tab

    var body: some View {
        VStack(spacing: 0) {
            if !appState.isAccessibilityGranted {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text("Accessibility permission is required for hotkeys to work.")
                    Spacer()
                    Button("Open Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .border(Color.yellow.opacity(0.3), width: 1)
            }
            
            TabView(selection: $selectedTab) {
                GeneralSettingsView() // Add the new General Settings view
                    .tabItem { Label("General", systemImage: "gearshape") }
                    .tag(TabSelection.general)
                
                ProviderSettingsView()
                    .environmentObject(modelStore) // Inject modelStore
                    .tabItem { Label("Providers", systemImage: "network") }
                    .tag(TabSelection.providers)
                
                ShortcutSettingsView()
                    .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                    .tag(TabSelection.shortcuts)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(ModelStore())
}
