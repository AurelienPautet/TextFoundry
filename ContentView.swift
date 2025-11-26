import SwiftUI

struct ContentView: View {
    @EnvironmentObject var promptStore: PromptStore
    
    @State private var inputText: String = "Type or paste text here to correct."
    @State private var var_correctedText: String = "Corrected text will appear here."
    @State private var selectedAIProvider: String = "Gemini" // Default to Gemini
    @State private var selectedPromptID: UUID?
    @State private var showingPromptManager: Bool = false
    @State private var showingSettings: Bool = false
    @State private var lmStudioAddress: String = "" // New state for LM Studio
    @State private var geminiAPIKey: String = ""
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false

    let aiProviders = ["Gemini", "LM Studio"] // Updated providers

    var body: some View {
        VStack(spacing: 15) {
            // TextEditor for input
            TextEditor(text: $inputText)
                .frame(minHeight: 150)
                .border(Color.gray.opacity(0.3), width: 1)
                .padding(.horizontal)
                .cornerRadius(5)

            // Controls
            HStack {
                Picker("AI Provider", selection: $selectedAIProvider) {
                    ForEach(aiProviders, id: \.self) { provider in
                        Text(provider).tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 200)

                Picker("Prompt", selection: $selectedPromptID) {
                    Text("Select Prompt").tag(nil as UUID?)
                    ForEach(promptStore.prompts) { prompt in
                        Text(prompt.name).tag(prompt.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 200)
                
                Button("Manage Prompts") {
                    showingPromptManager = true
                }
                .sheet(isPresented: $showingPromptManager) {
                    PromptManagerView()
                }

                Button("Settings") {
                    showingSettings = true
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }

                Spacer()

                Button("Correct") {
                    Task {
                        isLoading = true
                        defer { isLoading = false }

                        guard !inputText.isEmpty else {
                            errorMessage = "Input text cannot be empty."
                            showingErrorAlert = true
                            return
                        }

                        guard let selectedPrompt = promptStore.prompts.first(where: { $0.id == selectedPromptID }) else {
                            errorMessage = "Please select a prompt."
                            showingErrorAlert = true
                            return
                        }

                        // --- Updated dynamic service logic ---
                        let service: AIProviderService
                        let apiKey: String // This is now a generic key/address

                        switch selectedAIProvider {
                        case "LM Studio":
                            service = LMStudioService()
                            apiKey = lmStudioAddress
                        case "Gemini":
                            service = GeminiService()
                            apiKey = geminiAPIKey
                        default:
                            errorMessage = "Invalid AI Provider selected."
                            showingErrorAlert = true
                            return
                        }

                        guard !apiKey.isEmpty else {
                            errorMessage = "\(selectedAIProvider) API Key or Address is missing. Please set it in Settings."
                            showingErrorAlert = true
                            return
                        }

                        do {
                            var_correctedText = try await service.correctText(inputText, withPrompt: selectedPrompt.content, apiKey: apiKey)
                        } catch {
                            errorMessage = error.localizedDescription
                            showingErrorAlert = true
                        }
                        // --- End of updated logic ---
                    }
                }
                .controlSize(.large)
                .disabled(isLoading)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(.horizontal)

            // TextEditor for output
            TextEditor(text: $var_correctedText)
                .frame(minHeight: 150)
                .border(Color.gray.opacity(0.3), width: 1)
                .padding(.horizontal)
                .cornerRadius(5)
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .navigationTitle("AI Corrector")
        .onAppear {
            // Load keys/addresses on appear
            lmStudioAddress = UserDefaults.standard.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
            geminiAPIKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
            
            if selectedPromptID == nil {
                selectedPromptID = promptStore.prompts.first?.id
            }
        }
        .alert("Error", isPresented: $showingErrorAlert, actions: {
            Button("OK") { }
        }, message: {
            Text(errorMessage)
        })
    }
}

#Preview {
    ContentView()
}