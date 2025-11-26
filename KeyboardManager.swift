import Foundation
import CoreGraphics
import Carbon.HIToolbox // Import for key code constants

class KeyboardManager {
    static func simulateKeyPress(for key: CGKeyCode, with flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        keyDown?.flags = flags
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    static func copy() {
        // Simulate Cmd+C
        simulateKeyPress(for: CGKeyCode(kVK_ANSI_C), with: .maskCommand)
    }

    static func paste() {
        // Simulate Cmd+V
        simulateKeyPress(for: CGKeyCode(kVK_ANSI_V), with: .maskCommand)
    }
    
    static func pasteAndMatchStyle() {
        // Simulate Option+Shift+Cmd+V
        simulateKeyPress(for: CGKeyCode(kVK_ANSI_V), with: [.maskCommand, .maskShift, .maskAlternate])
    }
    
    static func keyCode(for char: String) -> CGKeyCode? {
        guard char.count == 1, let character = char.uppercased().first else { return nil }
        // This is a simplified map. A full map is very large.
        let keyMap: [Character: CGKeyCode] = [
            "A": CGKeyCode(kVK_ANSI_A), "B": CGKeyCode(kVK_ANSI_B), "C": CGKeyCode(kVK_ANSI_C),
            "D": CGKeyCode(kVK_ANSI_D), "E": CGKeyCode(kVK_ANSI_E), "F": CGKeyCode(kVK_ANSI_F),
            "G": CGKeyCode(kVK_ANSI_G), "H": CGKeyCode(kVK_ANSI_H), "I": CGKeyCode(kVK_ANSI_I),
            "J": CGKeyCode(kVK_ANSI_J), "K": CGKeyCode(kVK_ANSI_K), "L": CGKeyCode(kVK_ANSI_L),
            "M": CGKeyCode(kVK_ANSI_M), "N": CGKeyCode(kVK_ANSI_N), "O": CGKeyCode(kVK_ANSI_O),
            "P": CGKeyCode(kVK_ANSI_P), "Q": CGKeyCode(kVK_ANSI_Q), "R": CGKeyCode(kVK_ANSI_R),
            "S": CGKeyCode(kVK_ANSI_S), "T": CGKeyCode(kVK_ANSI_T), "U": CGKeyCode(kVK_ANSI_U),
            "V": CGKeyCode(kVK_ANSI_V), "W": CGKeyCode(kVK_ANSI_W), "X": CGKeyCode(kVK_ANSI_X),
            "Y": CGKeyCode(kVK_ANSI_Y), "Z": CGKeyCode(kVK_ANSI_Z),
            "0": CGKeyCode(kVK_ANSI_0), "1": CGKeyCode(kVK_ANSI_1), "2": CGKeyCode(kVK_ANSI_2),
            "3": CGKeyCode(kVK_ANSI_3), "4": CGKeyCode(kVK_ANSI_4), "5": CGKeyCode(kVK_ANSI_5),
            "6": CGKeyCode(kVK_ANSI_6), "7": CGKeyCode(kVK_ANSI_7), "8": CGKeyCode(kVK_ANSI_8),
            "9": CGKeyCode(kVK_ANSI_9),
        ]
        return keyMap[character]
    }
}
