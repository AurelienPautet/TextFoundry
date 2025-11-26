import Foundation

class APIService {
    static let shared = APIService()
    
    enum AIProvider {
        case gemini
        case lmStudio
    }

    // Refactored to handle system/user prompts and a model name
    func sendPrompt(to provider: AIProvider,
                    systemPrompt: String,
                    userPrompt: String,
                    apiKey: String,
                    modelName: String) async throws -> String {
        
        let endpoint: String
        let requestBody: [String: Any]
        
        switch provider {
        case .gemini:
            // The modelName is now part of the URL
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
            
            // For this simple API, we combine the system and user prompts.
            // A more advanced implementation might use a different structure if the API supports it.
            let fullPrompt = "\(systemPrompt)\n\n\(userPrompt)"
            requestBody = [
                "contents": [
                    ["parts": [["text": fullPrompt]]]
                ]
            ]
            
        case .lmStudio:
            // The 'apiKey' is the server address, modelName is passed in the body
            endpoint = "\(apiKey)/v1/chat/completions"
            
            // LM Studio uses the system/user role structure
            requestBody = [
                "model": modelName,
                "messages": [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": userPrompt]
                ],
                "temperature": 0.7
            ]
        }
        
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // --- DEBUGGING: Print the raw JSON response ---
        if let jsonString = String(data: data, encoding: .utf8) {
            print("--- Raw JSON Response from \(provider) ---")
            print(jsonString)
            print("------------------------------------")
        }
        
        if provider == .gemini {
            return try parseGeminiResponse(data: data)
        } else {
            return try parseLMStudioResponse(data: data)
        }
    }
    
    private func parseGeminiResponse(data: Data) throws -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return text
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let promptFeedback = json["promptFeedback"] as? [String: Any],
           let blockReason = promptFeedback["blockReason"] as? String {
            return "Error: Prompt was blocked. Reason: \(blockReason)"
        }
        return "Error parsing Gemini response or response was empty."
    }
    
    private func parseLMStudioResponse(data: Data) throws -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        return "Error parsing LM Studio response."
    }
    
    func fetchLMStudioModels(serverAddress: String) async throws -> [String] {
        let endpoint = "\(serverAddress)/v1/models"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataArray = json["data"] as? [[String: Any]] {
            return dataArray.compactMap { $0["id"] as? String }
        }
        return []
    }
}

