import Foundation
import Combine
import SwiftUI

class PromptStore: ObservableObject {
    @Published var prompts: [Prompt] = [] {
        didSet {
            savePrompts()
        }
    }
    private static let userDefaultsKey = "customPrompts"

    init() {
        loadPrompts()
    }

    private func savePrompts() {
        if let encoded = try? JSONEncoder().encode(prompts) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }

    private func loadPrompts() {
        if let savedPromptsData = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
           let decodedPrompts = try? JSONDecoder().decode([Prompt].self, from: savedPromptsData) {
            self.prompts = decodedPrompts
            return
        }
        
        // Load default prompts if none are saved
        self.prompts = [
            Prompt(name: "Grammar Correction", content: "Correct the grammar and spelling of the following text:"),
            Prompt(name: "Summarize", content: "Summarize the following text in one paragraph:"),
            Prompt(name: "Translate (English to French)", content: "Translate the following English text to French:")
        ]
    }
    
    func addPrompt(_ prompt: Prompt) {
        prompts.append(prompt)
    }
    
    func updatePrompt(id: UUID, name: String, content: String) {
        if let index = prompts.firstIndex(where: { $0.id == id }) {
            prompts[index].name = name
            prompts[index].content = content
        }
    }
    
    func deletePrompt(at offsets: IndexSet) {
        prompts.remove(atOffsets: offsets)
    }
    
    func deletePrompt(id: UUID) {
        prompts.removeAll { $0.id == id }
    }
}
