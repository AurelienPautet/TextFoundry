import Foundation
import SwiftUI
import Combine

class ModelStore: ObservableObject {
    @Published var models: [String] = [] {
        didSet {
            saveModels()
        }
    }
    private static let userDefaultsKey = "geminiModels"

    init() {
        loadModels()
    }

    private func saveModels() {
        UserDefaults.standard.set(models, forKey: Self.userDefaultsKey)
    }

    private func loadModels() {
        if let savedModels = UserDefaults.standard.stringArray(forKey: Self.userDefaultsKey) {
            self.models = savedModels
        } else {
            // Load default models if none are saved
            self.models = ["gemini-pro", "gemini-1.5-flash"]
        }
    }
    
    func addModel(_ modelName: String) {
        guard !modelName.isEmpty, !models.contains(modelName) else { return }
        models.append(modelName)
    }
    
    func deleteModel(at offsets: IndexSet) {
        models.remove(atOffsets: offsets)
    }

    func deleteModel(named modelName: String) {
        models.removeAll { $0 == modelName }
    }
}
