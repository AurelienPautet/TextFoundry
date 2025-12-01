import SwiftUI

struct ShortcutSettingsView: View {
    @EnvironmentObject var promptStore: PromptStore
    @EnvironmentObject var shortcutStore: ShortcutStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Text("Main Hotkey")) {
                    VStack(alignment: .leading) {
                        Text("This shortcut runs the prompt currently selected in the menu bar.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                        
                        ShortcutEditorRow(shortcut: $shortcutStore.mainShortcut)
                    }
                    .padding(8)
                }
                
                GroupBox(label: Text("Prompt-Specific Hotkeys")) {
                    VStack(spacing: 12) {
                        ForEach($promptStore.prompts) { $prompt in
                            ShortcutEditorRow(
                                promptName: prompt.name,
                                shortcut: Binding(
                                    get: { shortcutStore.shortcut(for: prompt.id) },
                                    set: { newShortcut in shortcutStore.updateShortcut(newShortcut) }
                                )
                            )
                            if prompt.id != promptStore.prompts.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(8)
                }
            }
            .padding()
        }
        .navigationTitle("Shortcuts")
    }
}

struct ShortcutEditorRow: View {
    var promptName: String?
    @Binding var shortcut: Shortcut
    
    @State private var key: String = ""
    
    var body: some View {
        HStack {
            if let promptName = promptName {
                Text(promptName)
                    .frame(width: 150, alignment: .leading)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text("Global Shortcut")
                    .frame(width: 150, alignment: .leading)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Toggle("⌘", isOn: $shortcut.command)
                    .toggleStyle(.button)
                    .frame(width: 35)
                
                Toggle("⇧", isOn: $shortcut.shift)
                    .toggleStyle(.button)
                    .frame(width: 35)
                
                Toggle("⌥", isOn: $shortcut.option)
                    .toggleStyle(.button)
                    .frame(width: 35)
                
                Toggle("⌃", isOn: $shortcut.control)
                    .toggleStyle(.button)
                    .frame(width: 35)
            }
            
            TextField("Key", text: $key)
                .frame(width: 50)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .onChange(of: key) {
                    // Only allow a single character
                    let filtered = key.uppercased().filter { "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains($0) }
                    DispatchQueue.main.async {
                        if let lastChar = filtered.last {
                            self.key = String(lastChar)
                            shortcut.key = self.key
                        } else {
                            self.key = ""
                            shortcut.key = ""
                        }
                    }
                }
        }
        .padding(.vertical, 4)
        .onAppear {
            key = shortcut.key
        }
    }
}

#Preview {
    ShortcutSettingsView()
        .environmentObject(PromptStore())
        .environmentObject(ShortcutStore())
}
