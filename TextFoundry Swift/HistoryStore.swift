import SwiftUI
import Foundation
import Combine

struct CorrectionHistoryItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let originalText: String
    let correctedText: String
    let date: Date
    let duration: TimeInterval
    let provider: String
    let model: String
    
    // New metrics
    var timeToFirstToken: TimeInterval?
    var tokenCount: Int?
    var tokensPerSecond: Double?
    var retryCount: Int?
    var promptTitle: String?
}

class HistoryStore: NSObject, ObservableObject {
    @Published var history: [CorrectionHistoryItem] = []
    
    private let saveKey = "correctionHistory"
    
    override init() {
        super.init()
        loadHistory()
    }
    
    func addItem(_ item: CorrectionHistoryItem) {
        DispatchQueue.main.async {
            self.history.insert(item, at: 0) // Add to top
            self.saveHistory()
        }
    }
    
    func clearHistory() {
        DispatchQueue.main.async {
            self.history.removeAll()
            self.saveHistory()
        }
    }
    
    func deleteItem(at offsets: IndexSet) {
        DispatchQueue.main.async {
            self.history.remove(atOffsets: offsets)
            self.saveHistory()
        }
    }
    
    private func saveHistory() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encoded = try? encoder.encode(history) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode([CorrectionHistoryItem].self, from: data) {
                self.history = decoded
                return
            }
        }
        // If decoding fails, or no data, load from old format for migration
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([CorrectionHistoryItem].self, from: data) {
            self.history = decoded
        }
    }
}
