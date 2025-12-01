import Foundation
import SwiftUI
import Combine

class ModelStore: ObservableObject {
    @Published var models: [String] = [] {
        didSet {
            saveModels()
        }
    }
    @Published var lmStudioModels: [String] = [] // Fetched from API
    @Published var openAIModels: [String] = [] {
        didSet {
            saveOpenAIModels()
        }
    }
    @Published var grokModels: [String] = [] {
        didSet {
            saveGrokModels()
        }
    }
    
    private static let userDefaultsKey = "geminiModels"
    private static let openAIUserDefaultsKey = "openAIModels"
    private static let grokUserDefaultsKey = "grokModels"

    init() {
        loadModels()
    }
    
    func fetchLMStudioModels(from address: String) async {
        do {
            let fetchedModels = try await APIService.shared.fetchLMStudioModels(serverAddress: address)
            DispatchQueue.main.async {
                self.lmStudioModels = fetchedModels
            }
        } catch {
            print("Failed to fetch LM Studio models: \(error)")
        }
    }

    private func saveModels() {
        UserDefaults.standard.set(models, forKey: Self.userDefaultsKey)
    }
    
    private func saveOpenAIModels() {
        UserDefaults.standard.set(openAIModels, forKey: Self.openAIUserDefaultsKey)
    }
    
    private func saveGrokModels() {
        UserDefaults.standard.set(grokModels, forKey: Self.grokUserDefaultsKey)
    }

    private func loadModels() {
        if let savedModels = UserDefaults.standard.stringArray(forKey: Self.userDefaultsKey) {
            self.models = savedModels
        } else {
            // Load default models if none are saved
            self.models = ["gemini-pro", "gemini-1.5-flash"]
        }
        
        if let savedOpenAI = UserDefaults.standard.stringArray(forKey: Self.openAIUserDefaultsKey) {
            self.openAIModels = savedOpenAI
        } else {
            self.openAIModels = ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"]
        }
        
        if let savedGrok = UserDefaults.standard.stringArray(forKey: Self.grokUserDefaultsKey) {
            self.grokModels = savedGrok
        } else {
            self.grokModels = ["grok-beta"]
        }
    }
    
    func addModel(_ modelName: String) {
        guard !modelName.isEmpty, !models.contains(modelName) else { return }
        models.append(modelName)
    }
    
    func addOpenAIModel(_ modelName: String) {
        guard !modelName.isEmpty, !openAIModels.contains(modelName) else { return }
        openAIModels.append(modelName)
    }
    
    func addGrokModel(_ modelName: String) {
        guard !modelName.isEmpty, !grokModels.contains(modelName) else { return }
        grokModels.append(modelName)
    }
    
    func deleteModel(at offsets: IndexSet) {
        models.remove(atOffsets: offsets)
    }

    func deleteModel(named modelName: String) {
        models.removeAll { $0 == modelName }
    }
    
    func deleteOpenAIModel(named modelName: String) {
        openAIModels.removeAll { $0 == modelName }
    }
    
    func deleteGrokModel(named modelName: String) {
        grokModels.removeAll { $0 == modelName }
    }
    
    func refreshAllModels(geminiKey: String, openAIKey: String, grokKey: String) async {
        // Gemini
        if !geminiKey.isEmpty {
            do {
                let fetched = try await APIService.shared.fetchGeminiModels(apiKey: geminiKey)
                if !fetched.isEmpty {
                    DispatchQueue.main.async {
                        self.models = fetched
                    }
                }
            } catch {
                print("Failed to refresh Gemini models: \(error)")
            }
        }
        
        // OpenAI
        if !openAIKey.isEmpty {
            do {
                let fetched = try await APIService.shared.fetchOpenAIModels(apiKey: openAIKey)
                if !fetched.isEmpty {
                    DispatchQueue.main.async {
                        self.openAIModels = fetched
                    }
                }
            } catch {
                print("Failed to refresh OpenAI models: \(error)")
            }
        }
        
        // Grok
        if !grokKey.isEmpty {
            do {
                let fetched = try await APIService.shared.fetchOpenAIModels(apiKey: grokKey, baseUrl: "https://api.x.ai/v1")
                if !fetched.isEmpty {
                    DispatchQueue.main.async {
                        self.grokModels = fetched
                    }
                }
            } catch {
                print("Failed to refresh Grok models: \(error)")
            }
        }
    }
}
