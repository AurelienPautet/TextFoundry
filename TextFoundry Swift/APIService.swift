import Foundation
import OpenAI

class APIService {
    static let shared = APIService()
    
    enum AIProvider {
        case gemini
        case lmStudio
        case openAI
        case grok
    }

    struct AIResponse {
        let text: String
        let tokenCount: Int
        let timeToFirstToken: TimeInterval
        var retryCount: Int = 0
    }

    func sendPrompt(to provider: AIProvider,
                    systemPrompt: String,
                    userPrompt: String,
                    apiKey: String,
                    modelName: String) async throws -> AIResponse {
        
        let maxRetries = UserDefaults.standard.integer(forKey: "retryCount")
        var currentAttempt = 0
        var lastError: Error?
        
        repeat {
            do {
                var response: AIResponse
                switch provider {
                case .gemini:
                    response = try await sendGeminiPrompt(systemPrompt: systemPrompt, userPrompt: userPrompt, apiKey: apiKey, modelName: modelName)
                case .lmStudio:
                    response = try await sendOpenAIPrompt(baseUrl: apiKey, token: "not-needed", model: modelName, systemPrompt: systemPrompt, userPrompt: userPrompt)
                case .openAI:
                    response = try await sendOpenAIPrompt(baseUrl: "https://api.openai.com/v1", token: apiKey, model: modelName, systemPrompt: systemPrompt, userPrompt: userPrompt)
                case .grok:
                    response = try await sendOpenAIPrompt(baseUrl: "https://api.x.ai/v1", token: apiKey, model: modelName, systemPrompt: systemPrompt, userPrompt: userPrompt)
                }
                
                // Attach the number of retries performed (currentAttempt is 0 on first try)
                response.retryCount = currentAttempt
                return response
                
            } catch {
                lastError = error
                if currentAttempt < maxRetries {
                    currentAttempt += 1
                    print("Attempt \(currentAttempt) failed: \(error). Retrying...")
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second before retry
                } else {
                    break
                }
            }
        } while currentAttempt <= maxRetries
        
        throw lastError ?? URLError(.unknown)
    }
    
    // MARK: - OpenAI (LM Studio, OpenAI, Grok) Implementation
    
    private func sendOpenAIPrompt(baseUrl: String, token: String, model: String, systemPrompt: String, userPrompt: String) async throws -> AIResponse {
        guard let url = URL(string: baseUrl),
              let host = url.host else {
            throw URLError(.badURL)
        }
        
        let port = url.port ?? (url.scheme == "https" ? 443 : 80)
        
        let configuration = OpenAI.Configuration(token: token, host: host, port: port, scheme: url.scheme ?? "https")
        let openAI = OpenAI(configuration: configuration)
        
        let query = ChatQuery(
            messages: [
                .init(role: .system, content: systemPrompt)!,
                .init(role: .user, content: userPrompt)!
            ],
            model: model
        )
        
        var fullText = ""
        var firstTokenTime: TimeInterval = 0
        let startTime = Date()
        var isFirstToken = true
        
        for try await chunk in openAI.chatsStream(query: query) {
            if let content = chunk.choices.first?.delta.content {
                if isFirstToken {
                    firstTokenTime = Date().timeIntervalSince(startTime)
                    isFirstToken = false
                }
                fullText += content
            }
        }
        
        // Estimate token count (chars / 4) since streaming doesn't always return usage
        let estimatedTokens = fullText.count / 4
        
        return AIResponse(text: fullText, tokenCount: estimatedTokens, timeToFirstToken: firstTokenTime)
    }
    
    // Custom struct for lenient decoding of LM Studio models
    struct LMStudioModelResponse: Decodable {
        let data: [LMStudioModel]
    }
    struct LMStudioModel: Decodable {
        let id: String
        // Some APIs return 'object' or 'type' field, but standard OpenAI format is 'id', 'object', 'owned_by'
        // LM Studio usually returns 'id' which is the model name.
        // To filter embeddings, we might need to check the ID string if the API doesn't provide type.
        // However, standard OpenAI /v1/models doesn't explicitly say "text-generation" vs "embedding" in a standard way across all providers.
        // But usually embedding models have "embedding" or "embed" in the name.
    }

    func fetchLMStudioModels(serverAddress: String) async throws -> [String] {
        // Ensure the URL ends with /v1/models
        var urlString = serverAddress
        if urlString.hasSuffix("/") {
            urlString = String(urlString.dropLast())
        }
        if !urlString.hasSuffix("/v1") {
            urlString += "/v1"
        }
        urlString += "/models"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(LMStudioModelResponse.self, from: data)
        
        // Filter out embedding models based on common naming conventions
        return response.data
            .map { $0.id }
            .filter { modelID in
                let lower = modelID.lowercased()
                return !lower.contains("embedding") && !lower.contains("embed")
            }
    }
    
    func fetchOpenAIModels(apiKey: String, baseUrl: String = "https://api.openai.com/v1") async throws -> [String] {
        guard let url = URL(string: baseUrl),
              let host = url.host else {
            throw URLError(.badURL)
        }
        
        let port = url.port ?? (url.scheme == "https" ? 443 : 80)
        let configuration = OpenAI.Configuration(token: apiKey, host: host, port: port, scheme: url.scheme ?? "https")
        let openAI = OpenAI(configuration: configuration)
        
        let result = try await openAI.models()
        return result.data.map { $0.id }
    }
    
    func fetchGeminiModels(apiKey: String) async throws -> [String] {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let models = json["models"] as? [[String: Any]] {
            return models.compactMap { modelDict in
                // Filter for models that support text generation
                if let supportedMethods = modelDict["supportedGenerationMethods"] as? [String],
                   supportedMethods.contains("generateContent"),
                   let name = modelDict["name"] as? String {
                    // Gemini model names come as "models/gemini-pro", we usually just want the short name or full name
                    // Let's keep the short name if possible, or just use what they give but strip "models/"
                    return name.replacingOccurrences(of: "models/", with: "")
                }
                return nil
            }
        }
        return []
    }

    // MARK: - Gemini Implementation (Raw HTTP)
    
    private func sendGeminiPrompt(systemPrompt: String, userPrompt: String, apiKey: String, modelName: String) async throws -> AIResponse {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        let fullPrompt = "\(systemPrompt)\n\n\(userPrompt)"
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": fullPrompt]]]
            ]
        ]
        
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let startTime = Date()
        let (data, _) = try await URLSession.shared.data(for: request)
        let duration = Date().timeIntervalSince(startTime)
        
        return try parseGeminiResponse(data: data, duration: duration)
    }
    
    private func parseGeminiResponse(data: Data, duration: TimeInterval) throws -> AIResponse {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            var tokenCount = 0
            if let usageMetadata = json["usageMetadata"] as? [String: Any],
               let candidatesTokenCount = usageMetadata["candidatesTokenCount"] as? Int {
                tokenCount = candidatesTokenCount
            }
            
            if let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                
                // If token count is missing, estimate
                if tokenCount == 0 {
                    tokenCount = text.count / 4
                }
                
                return AIResponse(text: text, tokenCount: tokenCount, timeToFirstToken: duration)
            }
            
            if let promptFeedback = json["promptFeedback"] as? [String: Any],
               let blockReason = promptFeedback["blockReason"] as? String {
                return AIResponse(text: "Error: Prompt was blocked. Reason: \(blockReason)", tokenCount: 0, timeToFirstToken: 0)
            }
        }
        return AIResponse(text: "Error parsing Gemini response or response was empty.", tokenCount: 0, timeToFirstToken: 0)
    }
}

