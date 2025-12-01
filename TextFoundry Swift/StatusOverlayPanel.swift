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
        self.hasShadow = false // Let SwiftUI view handle shadow to avoid border artifacts
        self.isMovableByWindowBackground = false
        
        let contentView = StatusOverlayView()
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.autoresizingMask = [.width, .height]
        hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 60) // Set initial frame
        self.contentView = hostingView
    }
    
    func show() {
        // Ensure we are on main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { self.show() }
            return
        }
        
        let mouseLocation = NSEvent.mouseLocation
        let panelSize = self.frame.size
        
        // Position top-left at cursor position
        let x = mouseLocation.x
        let y = mouseLocation.y - panelSize.height
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
        self.orderFront(nil)
    }
    
    func hide() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { self.hide() }
            return
        }
        self.orderOut(nil)
    }
}
