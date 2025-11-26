//
//  AI_Corrector_SwiftApp.swift
//  AI Corrector Swift
//
//  Created by Aurélien Pautet on 26/11/2025.
//

import SwiftUI
import AppKit // Add AppKit for NSApplicationDelegate

@main
struct AI_Corrector_SwiftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var promptStore = PromptStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(promptStore)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let hotkeyManager = HotkeyManager()
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyManager.setupHotkey()

        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "AI Corrector") // System icon
            button.action = #selector(menuBarItemClicked) // Action when button is clicked
            button.target = self
        }

        // Create the menu
        let menu = NSMenu()

        let showWindowMenuItem = NSMenuItem(title: "Show AI Corrector", action: #selector(showMainWindow), keyEquivalent: "")
        showWindowMenuItem.target = self
        menu.addItem(showWindowMenuItem)

        let hideWindowMenuItem = NSMenuItem(title: "Hide AI Corrector", action: #selector(hideMainWindow), keyEquivalent: "")
        hideWindowMenuItem.target = self
        menu.addItem(hideWindowMenuItem)

        menu.addItem(NSMenuItem.separator()) // Separator

        let quitMenuItem = NSMenuItem(title: "Quit AI Corrector", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitMenuItem.target = NSApp
        menu.addItem(quitMenuItem)

        statusItem?.menu = menu // Attach the menu to the status item
    }

    @objc func menuBarItemClicked(_ sender: Any?) {
        // Toggle main window visibility when menu bar icon is clicked directly
        if let window = NSApp.windows.first {
            if window.isVisible {
                window.orderOut(nil) // Hide
            } else {
                showMainWindow(sender) // Show
            }
        } else {
            showMainWindow(sender) // If no window exists, show it
        }
    }

    @objc func showMainWindow(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc func hideMainWindow(_ sender: Any?) {
        if let window = NSApp.windows.first {
            window.orderOut(nil)
        }
    }
}
