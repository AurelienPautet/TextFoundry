import SwiftUI

struct ShortcutSettingsView: View {
    @EnvironmentObject var promptStore: PromptStore
    @EnvironmentObject var shortcutStore: ShortcutStore

    var body: some View {
        VStack {
            Form {
                Section("Main Hotkey") {
                    Text("This shortcut runs the prompt currently selected in the menu bar.")
                        .font(.caption)
                    ShortcutEditorRow(shortcut: $shortcutStore.mainShortcut)
                }
                
                Section("Prompt-Specific Hotkeys") {
                    ForEach($promptStore.prompts) { $prompt in
                        ShortcutEditorRow(
                            promptName: prompt.name,
                            shortcut: Binding(
                                get: { shortcutStore.shortcut(for: prompt.id) },
                                set: { newShortcut in shortcutStore.updateShortcut(newShortcut) }
                            )
                        )
                    }
                }
            }
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
                Text(promptName).frame(width: 120, alignment: .leading)
            }
            
            Toggle("⌘", isOn: $shortcut.command)
            Toggle("⇧", isOn: $shortcut.shift)
            Toggle("⌥", isOn: $shortcut.option)
            Toggle("⌃", isOn: $shortcut.control)
            
            TextField("Key", text: $key)
                .frame(width: 40)
                .onChange(of: key) {
                    // Only allow a single character
                    let filtered = key.uppercased().filter { "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains($0) }
                    if let lastChar = filtered.last {
                        self.key = String(lastChar)
                        shortcut.key = self.key
                    } else {
                        self.key = ""
                        shortcut.key = ""
                    }
                }
        }
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
