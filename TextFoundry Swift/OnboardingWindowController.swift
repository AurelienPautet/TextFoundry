import SwiftUI
import AppKit

class OnboardingWindowController {
    static let shared = OnboardingWindowController()
    private var window: NSWindow?
    
    func show() {
        if window == nil {
            let view = OnboardingView(onFinished: { [weak self] in
                self?.close()
                // Notify app to open main window
                NotificationCenter.default.post(name: .openMainWindow, object: nil)
            })
            .environmentObject(AppViewModel.shared.appState)
            
            let hosting = NSHostingController(rootView: view)
            window = NSWindow(contentViewController: hosting)
            window?.setContentSize(NSSize(width: 600, height: 450))
            window?.styleMask = [.titled, .closable, .fullSizeContentView]
            window?.titlebarAppearsTransparent = true
            window?.title = "Welcome to TextFoundry"
            window?.center()
            window?.isReleasedWhenClosed = false
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.close()
        window = nil
    }
}

extension Notification.Name {
    static let openMainWindow = Notification.Name("OpenMainWindow")
}
