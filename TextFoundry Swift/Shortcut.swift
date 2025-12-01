import Foundation
import SwiftUI

// Represents a custom shortcut assigned to a specific prompt
struct Shortcut: Codable, Identifiable, Hashable {
    var id: UUID // The ID of the Prompt this shortcut is assigned to
    var key: String = ""
    var command: Bool = false
    var shift: Bool = false
    var option: Bool = false
    var control: Bool = false
    
    // A computed property to generate a display string like "⌘⇧C"
    var displayString: String {
        var result = ""
        if command { result += "⌘" }
        if shift { result += "⇧" }
        if option { result += "⌥" }
        if control { result += "⌃" }
        result += key.uppercased()
        return result
    }
    
    // Helper to get the CGEventFlags for the hotkey monitor
    var modifierFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if command { flags.insert(.maskCommand) }
        if shift { flags.insert(.maskShift) }
        if option { flags.insert(.maskAlternate) }
        if control { flags.insert(.maskControl) }
        return flags
    }
}
