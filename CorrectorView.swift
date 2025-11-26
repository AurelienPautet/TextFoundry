import SwiftUI

struct CorrectorView: View {
    @EnvironmentObject var promptStore: PromptStore
    @EnvironmentObject var modelStore: ModelStore
    @EnvironmentObject var appState: AppState
    
    // UI State
    @State private var inputText: String = "Type or paste text here to correct."
    @State private var correctedText: String = "Corrected text will appear here."

    // Provider & Prompt Selection
    @State private var selectedAIProvider: String = "Gemini"
    @State private var selectedPromptID: UUID?
    @State private var selectedGeminiModel: String = ""

    // Settings
    @State private var lmStudioAddress: String = ""
    @State private var geminiAPIKey: String = ""

    // Constants
    let aiProviders = ["Gemini", "LM Studio"]
    
    private var isBusy: Bool {
        if case .busy = appState.status { return true }
        return false
    }
    
    private var errorMessage: String {
        if case .error(let message) = appState.status { return message }
        return ""
    }

    var body: some View {
        VStack(spacing: 12) {
            // Top Controls
            HStack {
                Picker("Provider", selection: $selectedAIProvider) {
                    ForEach(aiProviders, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)

                if selectedAIProvider == "Gemini" {
                    Picker("Model", selection: $selectedGeminiModel) {
                        ForEach(modelStore.models, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 150)
                }
                
                Picker("Prompt", selection: $selectedPromptID) {
                    Text("Select Prompt").tag(nil as UUID?)
                    ForEach(promptStore.prompts) { prompt in
                        Text(prompt.name).tag(prompt.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)

            // Input / Output
            HSplitView {
                VStack(alignment: .leading) {
                    Text("Your Input").font(.headline)
                    TextEditor(text: $inputText)
                        .frame(minHeight: 200)
                }
                .padding(.leading)
                
                VStack(alignment: .leading) {
                    Text("Corrected Output").font(.headline)
                    TextEditor(text: $correctedText)
                        .frame(minHeight: 200)
                }
                .padding(.trailing)
            }
            
            // Bottom Bar
            HStack {
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
                Spacer()
                if isBusy {
                    ProgressView().controlSize(.small)
                }
                Button("Correct", action: { Task { await runCorrection() } })
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isBusy)
            }
            .padding([.horizontal, .bottom])
        }
        .padding(.top)
        .navigationTitle("Corrector")
        .onAppear(perform: loadSettings)
        .onChange(of: modelStore.models) {
            if !modelStore.models.contains(selectedGeminiModel) {
                selectedGeminiModel = modelStore.models.first ?? ""
            }
        }
        .onChange(of: selectedAIProvider) {
            UserDefaults.standard.set(selectedAIProvider, forKey: "selectedAIProvider")
        }
        .onChange(of: selectedPromptID) {
            UserDefaults.standard.set(selectedPromptID?.uuidString, forKey: "selectedPromptID")
        }
        .onChange(of: selectedGeminiModel) {
            UserDefaults.standard.set(selectedGeminiModel, forKey: "selectedGeminiModel")
        }
    }

    private func runCorrection() async {
        appState.status = .busy

        guard !inputText.isEmpty else {
            appState.status = .error(message: "Input text cannot be empty.")
            return
        }

        guard let selectedPrompt = promptStore.prompts.first(where: { $0.id == selectedPromptID }) else {
            appState.status = .error(message: "Please select a prompt.")
            return
        }

        let provider: APIService.AIProvider
        let apiKey: String
        let modelName: String

        switch selectedAIProvider {
        case "LM Studio":
            provider = .lmStudio
            apiKey = lmStudioAddress
            modelName = "local-model"
        case "Gemini":
            provider = .gemini
            apiKey = geminiAPIKey
            modelName = selectedGeminiModel
        default:
            appState.status = .error(message: "Invalid AI Provider selected.")
            return
        }
        
        guard !apiKey.isEmpty else {
            appState.status = .error(message: "\(selectedAIProvider) API Key or Address is missing.")
            return
        }

        do {
            let masterPrompt = UserDefaults.standard.string(forKey: "masterPrompt") ?? ""
            let combinedSystemPrompt = "\(masterPrompt)\n\n\(selectedPrompt.content)"

            correctedText = try await APIService.shared.sendPrompt(
                to: provider,
                systemPrompt: combinedSystemPrompt,
                userPrompt: inputText,
                apiKey: apiKey,
                modelName: modelName
            )
            appState.status = .ready
        } catch {
            appState.status = .error(message: error.localizedDescription)
        }
    }

    private func loadSettings() {
        lmStudioAddress = UserDefaults.standard.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
        geminiAPIKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        selectedAIProvider = UserDefaults.standard.string(forKey: "selectedAIProvider") ?? "Gemini"
        
        if let promptIDString = UserDefaults.standard.string(forKey: "selectedPromptID"),
           let promptID = UUID(uuidString: promptIDString),
           promptStore.prompts.contains(where: { $0.id == promptID }) {
            selectedPromptID = promptID
        } else {
            selectedPromptID = promptStore.prompts.first?.id
        }
        
        let savedModel = UserDefaults.standard.string(forKey: "selectedGeminiModel")
        if let savedModel = savedModel, !savedModel.isEmpty, modelStore.models.contains(savedModel) {
            selectedGeminiModel = savedModel
        } else {
            selectedGeminiModel = modelStore.models.first ?? ""
        }
    }
}

#Preview {
    CorrectorView()
        .environmentObject(PromptStore())
        .environmentObject(ModelStore())
        .environmentObject(AppState())
}
