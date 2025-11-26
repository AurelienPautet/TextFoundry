import Foundation
import Combine

enum AppStatus {
    case ready
    case busy
    case error(message: String)
}

enum Panel: String, CaseIterable {
    case corrector
    case masterPrompt
    case prompts
    case history
    case settings
}

class AppState: ObservableObject {
    @Published var status: AppStatus = .ready
    @Published var selectedPanel: Panel? = .corrector
    
    // Shared selection state
    @Published var selectedAIProvider: String {
        didSet {
            UserDefaults.standard.set(selectedAIProvider, forKey: "selectedAIProvider")
        }
    }
    @Published var selectedGeminiModel: String {
        didSet {
            UserDefaults.standard.set(selectedGeminiModel, forKey: "selectedGeminiModel")
        }
    }
    @Published var selectedLMStudioModel: String {
        didSet {
            UserDefaults.standard.set(selectedLMStudioModel, forKey: "selectedLMStudioModel")
        }
    }
    
    @Published var isAccessibilityGranted: Bool = false
    
    init() {
        self.selectedAIProvider = UserDefaults.standard.string(forKey: "selectedAIProvider") ?? "Gemini"
        self.selectedGeminiModel = UserDefaults.standard.string(forKey: "selectedGeminiModel") ?? ""
        self.selectedLMStudioModel = UserDefaults.standard.string(forKey: "selectedLMStudioModel") ?? ""
    }
}
