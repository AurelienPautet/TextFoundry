import Foundation
import OpenAI

class GeminiService: AIProviderService {
    let name: String = "Gemini"

    func correctText(_ text: String, withPrompt prompt: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIServiceError.apiKeyMissing
        }

        // Configure for Gemini API
        let configuration = OpenAI.Configuration(
            token: apiKey,
            host: "generativelanguage.googleapis.com",
            scheme: "https",
            basePath: "/v1beta", // Adjusted for Gemini API
            parsingOptions: .relaxed // Added parsing option for compatibility
        )
        
        let openAI = OpenAI(configuration: configuration)

        // Construct the messages for the chat completion
        // Gemini might use a different format for system prompts.
        let messages: [ChatQuery.ChatCompletionMessageParam] = [
            .init(role: .system, content: prompt),
            .init(role: .user, content: text)
        ].compactMap { $0 }

        // Use a Gemini model
        let chatQuery = ChatQuery(messages: messages, model: "gemini-pro")

        do {
            let chatCompletion = try await openAI.chats(query: chatQuery)
            if let firstChoice = chatCompletion.choices.first {
                return firstChoice.message.content ?? "No correction available."
            } else {
                return "No correction available."
            }
        } catch {
            print("Gemini API Error: \(error)")
            throw AIServiceError.apiError(error.localizedDescription)
        }
    }
}
