import Foundation
import Combine

class ShortcutStore: ObservableObject {
    @Published var shortcuts: [Shortcut] = [] {
        didSet {
            saveShortcuts()
        }
    }
    private static let userDefaultsKey = "customShortcuts"

    init() {
        loadShortcuts()
    }

    // A special shortcut for the main, context-aware hotkey
    var mainShortcut: Shortcut {
        get {
            // Use a fixed UUID for the main shortcut
            let mainShortcutID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            return shortcuts.first(where: { $0.id == mainShortcutID }) ?? Shortcut(id: mainShortcutID, key: "C", command: true, shift: true)
        }
        set {
            if let index = shortcuts.firstIndex(where: { $0.id == newValue.id }) {
                shortcuts[index] = newValue
            } else {
                shortcuts.append(newValue)
            }
        }
    }
    
    // Get a shortcut for a specific prompt ID
    func shortcut(for promptID: UUID) -> Shortcut {
        return shortcuts.first(where: { $0.id == promptID }) ?? Shortcut(id: promptID)
    }

    // Update or create a shortcut
    func updateShortcut(_ shortcut: Shortcut) {
        // Only update if there are actual changes
        if shortcut.key.isEmpty && !shortcut.command && !shortcut.shift && !shortcut.option && !shortcut.control {
            // If all fields are empty/false, remove the shortcut
            shortcuts.removeAll { $0.id == shortcut.id }
        } else {
            if let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
                shortcuts[index] = shortcut
            } else {
                shortcuts.append(shortcut)
            }
        }
    }

    private func saveShortcuts() {
        if let encoded = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }

    private func loadShortcuts() {
        if let savedData = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
           let decodedShortcuts = try? JSONDecoder().decode([Shortcut].self, from: savedData) {
            self.shortcuts = decodedShortcuts
        } else {
            // Initialize with a default main shortcut
            let mainShortcutID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            self.shortcuts = [Shortcut(id: mainShortcutID, key: "C", command: true, shift: true)]
        }
    }
}
