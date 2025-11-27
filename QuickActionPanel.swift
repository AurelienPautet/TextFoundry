import SwiftUI
import AppKit

enum QuickActionSelection {
    case savedPrompt(UUID)
    case customPrompt(String)
}

class QuickActionPanel: NSPanel {
    static let shared = QuickActionPanel()
    
    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.borderless], // Removed nonactivatingPanel to allow key focus
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.isMovableByWindowBackground = false
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    func show(at point: NSPoint, promptStore: PromptStore, customPromptStore: CustomPromptHistoryStore, appState: AppState, onSelect: @escaping (QuickActionSelection) -> Void) {
        let contentView = QuickActionView(
            onSelect: { [weak self] selection in
                self?.close()
                onSelect(selection)
            },
            onCancel: { [weak self] in
                self?.close()
            }
        )
        .environmentObject(promptStore)
        .environmentObject(customPromptStore)
        .environmentObject(appState)
        
        self.contentView = NSHostingView(rootView: contentView)
        
        // Calculate height based on content
        let rowHeight: CGFloat = 44
        let headerHeight: CGFloat = 50 // Approx header height
        let contentHeight = min(CGFloat(promptStore.prompts.count) * rowHeight, 300) + headerHeight
        let panelSize = NSSize(width: 400, height: contentHeight)
        
        self.setContentSize(panelSize)
        
        // Calculate position (centered horizontally on mouse, slightly below)
        // Or just near mouse. Let's try to center it on the screen for better visibility like Spotlight,
        // OR follow the user request "near the cursor".
        // "near the cursor" usually means slightly below-right or centered on cursor.
        
        // Let's center it on the screen where the mouse is.
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) {
            let screenRect = screen.visibleFrame
            
            // Center on screen
            let x = screenRect.midX - (panelSize.width / 2)
            let y = screenRect.midY - (panelSize.height / 2) + 100 // Slightly higher than center looks better
            
            self.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            self.center()
        }
        
        self.makeKeyAndOrderFront(nil)
        // Only activate the app if it's not already active to avoid bringing main window to front unnecessarily
        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
