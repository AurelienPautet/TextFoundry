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

    init(appState: AppState, shortcutStore: ShortcutStore, promptStore: PromptStore, historyStore: HistoryStore) {
        self.appState = appState
        self.shortcutStore = shortcutStore
        self.promptStore = promptStore
        self.historyStore = historyStore
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
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
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

    private func performCorrectionAction(for promptID: UUID) async {
        DispatchQueue.main.async { self.appState?.status = .busy }
        
        let startTime = Date()
        
        // Play start sound
        NSSound(named: "Tink")?.play()
        
        // We no longer restore the original clipboard so the user keeps the corrected text
        // let originalClipboardContent = ClipboardManager.read()
        
        KeyboardManager.copy()
        try? await Task.sleep(for: .milliseconds(200))
        guard let selectedText = ClipboardManager.read(), !selectedText.isEmpty else {
            print("Hotkey Error: No text selected or clipboard is empty.")
            NSSound(named: "Basso")?.play() // Play error sound
            DispatchQueue.main.async { self.appState?.status = .ready }
            return
        }

        let defaults = UserDefaults.standard
        let providerName = defaults.string(forKey: "selectedAIProvider") ?? "Gemini"
        let geminiModel = defaults.string(forKey: "selectedGeminiModel") ?? "gemini-pro"
        let lmStudioModel = defaults.string(forKey: "selectedLMStudioModel") ?? "local-model"
        let geminiAPIKey = defaults.string(forKey: "geminiAPIKey") ?? ""
        let lmStudioAddress = defaults.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
        
        guard let selectedPrompt = self.promptStore?.prompts.first(where: { $0.id == promptID }) else {
            print("Hotkey Error: Could not find prompt with ID \(promptID).")
            NSSound(named: "Basso")?.play() // Play error sound
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
        default:
            print("Hotkey Error: Invalid provider found in UserDefaults.")
            NSSound(named: "Basso")?.play() // Play error sound
            DispatchQueue.main.async { self.appState?.status = .error(message: "Invalid provider.") }
            return
        }

        do {
            let masterPrompt = defaults.string(forKey: "masterPrompt") ?? ""
            let combinedSystemPrompt = "\(masterPrompt)\n\n\(selectedPrompt.content)"
            
            let correctedText = try await APIService.shared.sendPrompt(
                to: provider,
                systemPrompt: combinedSystemPrompt,
                userPrompt: selectedText,
                apiKey: apiKey,
                modelName: modelName
            )
            
            ClipboardManager.write(correctedText)
            try? await Task.sleep(for: .milliseconds(100))
            KeyboardManager.paste()
            
            // Play success sound
            NSSound(named: "Glass")?.play()
            
            // Save to history
            let duration = Date().timeIntervalSince(startTime)
            let historyItem = CorrectionHistoryItem(
                originalText: selectedText,
                correctedText: correctedText,
                date: Date(),
                duration: duration,
                provider: providerName,
                model: modelName
            )
            self.historyStore?.addItem(historyItem)
            
            DispatchQueue.main.async { self.appState?.status = .ready }
            
        } catch {
            print("Hotkey Error: API call failed. \(error.localizedDescription)")
            NSSound(named: "Basso")?.play() // Play error sound
            DispatchQueue.main.async { self.appState?.status = .error(message: "API Error.") }
        }
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
