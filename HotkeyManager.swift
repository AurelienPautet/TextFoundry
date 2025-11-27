import Foundation
import SwiftUI
import Carbon.HIToolbox
import Accessibility

class HotkeyManager {
    private var eventMonitor: Any?
    private weak var appState: AppState?
    private weak var shortcutStore: ShortcutStore?
    private weak var promptStore: PromptStore?
    private weak var historyStore: HistoryStore?
    private weak var customPromptHistoryStore: CustomPromptHistoryStore?

    init(appState: AppState, shortcutStore: ShortcutStore, promptStore: PromptStore, historyStore: HistoryStore, customPromptHistoryStore: CustomPromptHistoryStore) {
        self.appState = appState
        self.shortcutStore = shortcutStore
        self.promptStore = promptStore
        self.historyStore = historyStore
        self.customPromptHistoryStore = customPromptHistoryStore
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func setupMonitoring() {
        // Check for accessibility permissions and prompt if not granted
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        DispatchQueue.main.async {
            self.appState?.isAccessibilityGranted = accessEnabled
        }

        if !accessEnabled {
            print("Accessibility permission not granted. Please enable it in System Settings > Privacy & Security > Accessibility.")
            return
        }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event: event)
        }
    }
    
    private func handle(event: NSEvent) {
        guard let shortcutStore = self.shortcutStore else { return }
        
        // Prevent double execution
        if case .busy = appState?.status { return }
        
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Check Quick Action Shortcut
        let quickAction = shortcutStore.quickActionShortcut
        if let qaKeyCode = KeyboardManager.keyCode(for: quickAction.key),
           flags == NSEvent.ModifierFlags(rawValue: UInt(quickAction.modifierFlags.rawValue)) && event.keyCode == qaKeyCode {
             print("Quick Action Hotkey pressed!")
             Task { await self.showQuickActionPanel() }
             return
        }
        
        for shortcut in shortcutStore.shortcuts {
            guard let keyCode = KeyboardManager.keyCode(for: shortcut.key) else { continue }
            
            // Convert CGEventFlags to NSEvent.ModifierFlags for comparison
            if flags == NSEvent.ModifierFlags(rawValue: UInt(shortcut.modifierFlags.rawValue)) && event.keyCode == keyCode {
                print("Hotkey '\(shortcut.displayString)' pressed!")
                
                let mainShortcutID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                var promptIdToUse: UUID? = shortcut.id
                
                if shortcut.id == mainShortcutID {
                    let promptIDString = UserDefaults.standard.string(forKey: "selectedPromptID")
                    promptIdToUse = UUID(uuidString: promptIDString ?? "")
                }
                
                guard let finalPromptID = promptIdToUse else {
                    print("Hotkey Error: Could not determine which prompt to run.")
                    return
                }
                
                Task {
                    await self.performCorrectionAction(for: finalPromptID)
                }
                return
            }
        }
    }

    private func showQuickActionPanel() async {
        // 1. Copy text
        KeyboardManager.copy()
        try? await Task.sleep(for: .milliseconds(200))
        guard let selectedText = ClipboardManager.read(), !selectedText.isEmpty else {
            SoundManager.shared.play(named: "Basso")
            return
        }
        
        // 2. Show Panel
        DispatchQueue.main.async {
            guard let promptStore = self.promptStore, 
                  let appState = self.appState,
                  let customPromptStore = self.customPromptHistoryStore else { return }
            
            let mouseLocation = NSEvent.mouseLocation
            QuickActionPanel.shared.show(at: mouseLocation, promptStore: promptStore, customPromptStore: customPromptStore, appState: appState) { [weak self] selection in
                
                // Hide app to return focus to previous app
                NSApp.hide(nil)
                
                Task {
                    // Wait a bit for focus to switch back
                    try? await Task.sleep(for: .milliseconds(300))
                    
                    switch selection {
                    case .savedPrompt(let promptID):
                        // Sync selection
                        UserDefaults.standard.set(promptID.uuidString, forKey: "selectedPromptID")
                        await self?.performCorrectionAction(for: promptID, textToCorrect: selectedText)
                    case .customPrompt(let customText):
                        await self?.performCorrectionAction(customPrompt: customText, textToCorrect: selectedText)
                    }
                }
            }
        }
    }

    private func performCorrectionAction(for promptID: UUID? = nil, customPrompt: String? = nil, textToCorrect: String? = nil) async {
        DispatchQueue.main.async { 
            self.appState?.status = .busy 
            if UserDefaults.standard.bool(forKey: "showLoadingOverlay") {
                StatusOverlayPanel.shared.show()
            }
        }
        
        defer {
            DispatchQueue.main.async {
                StatusOverlayPanel.shared.hide()
            }
        }
        
        let startTime = Date()
        
        // Play start sound
        SoundManager.shared.play(named: "Tink")
        
        var selectedText = textToCorrect
        
        if selectedText == nil {
            KeyboardManager.copy()
            try? await Task.sleep(for: .milliseconds(200))
            selectedText = ClipboardManager.read()
        }
        
        guard let finalText = selectedText, !finalText.isEmpty else {
            print("Hotkey Error: No text selected or clipboard is empty.")
            SoundManager.shared.play(named: "Basso") // Play error sound
            DispatchQueue.main.async { self.appState?.status = .ready }
            return
        }

        let defaults = UserDefaults.standard
        let providerName = defaults.string(forKey: "selectedAIProvider") ?? "Gemini"
        let geminiModel = defaults.string(forKey: "selectedGeminiModel") ?? "gemini-pro"
        let lmStudioModel = defaults.string(forKey: "selectedLMStudioModel") ?? "local-model"
        let openAIModel = defaults.string(forKey: "selectedOpenAIModel") ?? "gpt-4o"
        let grokModel = defaults.string(forKey: "selectedGrokModel") ?? "grok-beta"
        
        let geminiAPIKey = defaults.string(forKey: "geminiAPIKey") ?? ""
        let lmStudioAddress = defaults.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
        let openAIAPIKey = defaults.string(forKey: "openAIAPIKey") ?? ""
        let grokAPIKey = defaults.string(forKey: "grokAPIKey") ?? ""
        
        // Determine Prompt Content
        var promptContent = ""
        var promptName = ""
        
        if let custom = customPrompt {
            promptContent = custom
            promptName = "Custom Prompt"
            self.customPromptHistoryStore?.addPrompt(custom)
        } else if let id = promptID {
            if let prompt = self.promptStore?.prompts.first(where: { $0.id == id }) {
                promptContent = prompt.content
                promptName = prompt.name
            } else if let customPrompt = self.customPromptHistoryStore?.history.first(where: { $0.id == id }) {
                promptContent = customPrompt.content
                promptName = "Custom Prompt"
            } else {
                print("Hotkey Error: No prompt selected.")
                SoundManager.shared.play(named: "Basso")
                DispatchQueue.main.async { self.appState?.status = .error(message: "No prompt selected.") }
                return
            }
        } else {
            print("Hotkey Error: No prompt selected.")
            SoundManager.shared.play(named: "Basso")
            DispatchQueue.main.async { self.appState?.status = .error(message: "No prompt selected.") }
            return
        }
        
        let provider: APIService.AIProvider
        let apiKey: String
        let modelName: String

        switch providerName {
        case "LM Studio":
            provider = .lmStudio
            apiKey = lmStudioAddress
            modelName = lmStudioModel.isEmpty ? "local-model" : lmStudioModel
        case "Gemini":
            provider = .gemini
            apiKey = geminiAPIKey
            modelName = geminiModel
        case "OpenAI":
            provider = .openAI
            apiKey = openAIAPIKey
            modelName = openAIModel
        case "xAI Grok":
            provider = .grok
            apiKey = grokAPIKey
            modelName = grokModel
        default:
            print("Hotkey Error: Invalid provider found in UserDefaults.")
            SoundManager.shared.play(named: "Basso") // Play error sound
            DispatchQueue.main.async { self.appState?.status = .error(message: "Invalid provider.") }
            return
        }
        
        if apiKey.isEmpty {
            print("Hotkey Error: Missing API Key for \(providerName).")
            SoundManager.shared.play(named: "Basso")
            DispatchQueue.main.async { self.appState?.status = .error(message: "Missing API Key for \(providerName).") }
            return
        }

        do {
            let masterPrompt = defaults.string(forKey: "masterPrompt") ?? ""
            let combinedSystemPrompt = "\(masterPrompt)\n\n\(promptContent)"
            
            let response = try await APIService.shared.sendPrompt(
                to: provider,
                systemPrompt: combinedSystemPrompt,
                userPrompt: finalText,
                apiKey: apiKey,
                modelName: modelName
            )
            
            ClipboardManager.write(response.text)
            try? await Task.sleep(for: .milliseconds(100))
            
            // Always use standard paste (Cmd+V) because we are pasting plain text.
            // This effectively matches the destination style in most apps.
            // The "Smart Paste" option is kept for legacy reasons or if we add rich text later,
            // but for now both paths do the same thing to ensure reliability.
            KeyboardManager.paste()
            
            // Play success sound
            SoundManager.shared.play(named: "Glass")
            
            // Save to history
            let duration = Date().timeIntervalSince(startTime)
            let tps = duration > 0 ? Double(response.tokenCount) / duration : 0
            
            let historyItem = CorrectionHistoryItem(
                originalText: finalText,
                correctedText: response.text,
                date: Date(),
                duration: duration,
                provider: providerName,
                model: modelName,
                timeToFirstToken: response.timeToFirstToken,
                tokenCount: response.tokenCount,
                tokensPerSecond: tps,
                retryCount: response.retryCount,
                promptTitle: promptName
            )
            self.historyStore?.addItem(historyItem)
            
            DispatchQueue.main.async {
                self.appState?.lastRunStats = historyItem
                self.appState?.status = .ready
            }
            
        } catch {
            print("Hotkey Error: API call failed. \(error.localizedDescription)")
            SoundManager.shared.play(named: "Basso") // Play error sound
            DispatchQueue.main.async { self.appState?.status = .error(message: "API Error.") }
        }
    }
    
    func correctClipboard(promptID: UUID) async {
        if case .busy = appState?.status { return }
        DispatchQueue.main.async { self.appState?.status = .busy }
        
        let startTime = Date()
        
        // Play start sound
        SoundManager.shared.play(named: "Tink")
        
        guard let clipboardText = ClipboardManager.read(), !clipboardText.isEmpty else {
            print("Clipboard Error: Clipboard is empty.")
            SoundManager.shared.play(named: "Basso") // Play error sound
            DispatchQueue.main.async { self.appState?.status = .error(message: "Clipboard is empty.") }
            return
        }

        let defaults = UserDefaults.standard
        let providerName = appState?.selectedAIProvider ?? "Gemini"
        
        // Get models from AppState if possible, otherwise fallback to defaults
        let geminiModel = appState?.selectedGeminiModel ?? defaults.string(forKey: "selectedGeminiModel") ?? "gemini-pro"
        let lmStudioModel = appState?.selectedLMStudioModel ?? defaults.string(forKey: "selectedLMStudioModel") ?? "local-model"
        let openAIModel = appState?.selectedOpenAIModel ?? defaults.string(forKey: "selectedOpenAIModel") ?? "gpt-4o"
        let grokModel = appState?.selectedGrokModel ?? defaults.string(forKey: "selectedGrokModel") ?? "grok-beta"
        
        let geminiAPIKey = defaults.string(forKey: "geminiAPIKey") ?? ""
        let lmStudioAddress = defaults.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
        let openAIAPIKey = defaults.string(forKey: "openAIAPIKey") ?? ""
        let grokAPIKey = defaults.string(forKey: "grokAPIKey") ?? ""
        
        guard let selectedPrompt = self.promptStore?.prompts.first(where: { $0.id == promptID }) else {
            print("Clipboard Error: Could not find prompt with ID \(promptID).")
            SoundManager.shared.play(named: "Basso") // Play error sound
            DispatchQueue.main.async { self.appState?.status = .error(message: "Prompt not found.") }
            return
        }
        
        let provider: APIService.AIProvider
        let apiKey: String
        let modelName: String

        switch providerName {
        case "LM Studio":
            provider = .lmStudio
            apiKey = lmStudioAddress
            modelName = lmStudioModel.isEmpty ? "local-model" : lmStudioModel
        case "Gemini":
            provider = .gemini
            apiKey = geminiAPIKey
            modelName = geminiModel
        case "OpenAI":
            provider = .openAI
            apiKey = openAIAPIKey
            modelName = openAIModel
        case "xAI Grok":
            provider = .grok
            apiKey = grokAPIKey
            modelName = grokModel
        default:
            print("Clipboard Error: Invalid provider found.")
            SoundManager.shared.play(named: "Basso") // Play error sound
            DispatchQueue.main.async { self.appState?.status = .error(message: "Invalid provider.") }
            return
        }
        
        if apiKey.isEmpty {
            print("Clipboard Error: Missing API Key for \(providerName).")
            SoundManager.shared.play(named: "Basso")
            DispatchQueue.main.async { self.appState?.status = .error(message: "Missing API Key for \(providerName).") }
            return
        }

        do {
            let masterPrompt = defaults.string(forKey: "masterPrompt") ?? ""
            let combinedSystemPrompt = "\(masterPrompt)\n\n\(selectedPrompt.content)"
            
            let response = try await APIService.shared.sendPrompt(
                to: provider,
                systemPrompt: combinedSystemPrompt,
                userPrompt: clipboardText,
                apiKey: apiKey,
                modelName: modelName
            )
            
            ClipboardManager.write(response.text)
            
            // Play success sound
            SoundManager.shared.play(named: "Glass")
            
            // Save to history
            let duration = Date().timeIntervalSince(startTime)
            let tps = duration > 0 ? Double(response.tokenCount) / duration : 0
            
            let historyItem = CorrectionHistoryItem(
                originalText: clipboardText,
                correctedText: response.text,
                date: Date(),
                duration: duration,
                provider: providerName,
                model: modelName,
                timeToFirstToken: response.timeToFirstToken,
                tokenCount: response.tokenCount,
                tokensPerSecond: tps,
                retryCount: response.retryCount,
                promptTitle: selectedPrompt.name
            )
            self.historyStore?.addItem(historyItem)
            
            DispatchQueue.main.async {
                self.appState?.lastRunStats = historyItem
                self.appState?.status = .ready
            }
            
        } catch {
            print("Clipboard Error: API call failed. \(error.localizedDescription)")
            SoundManager.shared.play(named: "Basso") // Play error sound
            DispatchQueue.main.async { self.appState?.status = .error(message: error.localizedDescription) }
        }
    }
}
