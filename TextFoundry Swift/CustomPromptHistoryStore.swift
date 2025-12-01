import Foundation
import Combine
import SwiftUI

struct CustomPromptHistoryItem: Identifiable, Codable {
    var id = UUID()
    let content: String
    let date: Date
}

class CustomPromptHistoryStore: ObservableObject {
    @Published var history: [CustomPromptHistoryItem] = []
    private let saveKey = "customPromptHistory"
    
    init() {
        loadHistory()
    }
    
    func addPrompt(_ content: String) {
        let item = CustomPromptHistoryItem(content: content, date: Date())
        DispatchQueue.main.async {
            // Remove duplicates if any, to keep only the latest one
            self.history.removeAll { $0.content == content }
            self.history.insert(item, at: 0)
            self.saveHistory()
        }
    }
    
    func deletePrompt(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }
    
    func deletePrompt(id: UUID) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history.remove(at: index)
            saveHistory()
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([CustomPromptHistoryItem].self, from: data) {
            self.history = decoded
        }
    }
}
