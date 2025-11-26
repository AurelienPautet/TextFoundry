import SwiftUI
import AppKit

class StatusOverlayPanel: NSPanel {
    static let shared = StatusOverlayPanel()
    
    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
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
        
        let contentView = StatusOverlayView()
        self.contentView = NSHostingView(rootView: contentView)
    }
    
    func show() {
        // Center on the screen with the mouse or main screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let panelSize = self.frame.size
            
            // Position at the bottom center or center
            let x = screenRect.midX - (panelSize.width / 2)
            let y = screenRect.minY + 100 // 100px from bottom
            
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        self.orderFront(nil)
    }
    
    func hide() {
        self.orderOut(nil)
    }
}
