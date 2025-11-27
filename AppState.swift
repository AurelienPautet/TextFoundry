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
    case customPrompts
    case history
    case stats
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
    @Published var selectedOpenAIModel: String {
        didSet {
            UserDefaults.standard.set(selectedOpenAIModel, forKey: "selectedOpenAIModel")
        }
    }
    @Published var selectedGrokModel: String {
        didSet {
            UserDefaults.standard.set(selectedGrokModel, forKey: "selectedGrokModel")
        }
    }
    
        @Published var isAccessibilityGranted: Bool = false
    
    // Last Run Stats
    @Published var lastRunStats: CorrectionHistoryItem?
    
    init() {
        self.selectedAIProvider = UserDefaults.standard.string(forKey: "selectedAIProvider") ?? "Gemini"
        self.selectedGeminiModel = UserDefaults.standard.string(forKey: "selectedGeminiModel") ?? ""
        self.selectedLMStudioModel = UserDefaults.standard.string(forKey: "selectedLMStudioModel") ?? ""
        self.selectedOpenAIModel = UserDefaults.standard.string(forKey: "selectedOpenAIModel") ?? ""
        self.selectedGrokModel = UserDefaults.standard.string(forKey: "selectedGrokModel") ?? ""
    }
}
