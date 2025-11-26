import Foundation
import OpenAI

// The 'apiKey' can be an actual key for cloud services, or a URL for local servers.
protocol AIProviderService {
    var name: String { get }
    func correctText(_ text: String, withPrompt prompt: String, apiKey: String) async throws -> String
}

class LMStudioService: AIProviderService {
    let name: String = "LM Studio"

    func correctText(_ text: String, withPrompt prompt: String, apiKey address: String) async throws -> String {
        guard let url = URL(string: address) else {
            throw AIServiceError.apiError("Invalid LM Studio address URL.")
        }

        let configuration = OpenAI.Configuration(
            token: "lm-studio", // Token can be a dummy string for LM Studio
            host: url.host ?? "localhost",
            scheme: url.scheme ?? "http",
            port: url.port ?? 1234,
            basePath: "/v1"
        )
        let openAI = OpenAI(configuration: configuration)

        let messages: [ChatQuery.ChatCompletionMessageParam] = [
            .init(role: .system, content: prompt),
            .init(role: .user, content: text)
        ].compactMap { $0 }

        // Model name can be anything when using LM Studio, as it's determined by the loaded model in the app.
        let chatQuery = ChatQuery(model: "local-model", messages: messages)

        do {
            let chatCompletion = try await openAI.chats(query: chatQuery)
            if let firstChoice = chatCompletion.choices.first {
                return firstChoice.message.content ?? "No correction available."
            } else {
                return "No correction available."
            }
        } catch {
            print("LM Studio Error: \(error)")
            throw AIServiceError.apiError(error.localizedDescription)
        }
    }
}


// Define custom errors for the AI service
enum AIServiceError: Error, LocalizedError {
    case apiKeyMissing
    case apiError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API Key or Address is missing. Please set it in Settings."
        case .apiError(let message):
            return "AI API Error: \(message)"
        case .unknown:
            return "An unknown error occurred with the AI service."
        }
    }
}
