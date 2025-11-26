import SwiftUI

struct CorrectorView: View {
    @EnvironmentObject var promptStore: PromptStore
    @EnvironmentObject var modelStore: ModelStore
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var historyStore: HistoryStore
    
    // UI State
    @State private var inputText: String = "Type or paste text here to correct."
    @State private var correctedText: String = "Corrected text will appear here."

    // Provider & Prompt Selection
    @State private var selectedPromptID: UUID?

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
                Picker("Provider", selection: $appState.selectedAIProvider) {
                    ForEach(aiProviders, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)

                if appState.selectedAIProvider == "Gemini" {
                    Picker("Model", selection: $appState.selectedGeminiModel) {
                        ForEach(modelStore.models, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 150)
                } else if appState.selectedAIProvider == "LM Studio" {
                    Picker("Model", selection: $appState.selectedLMStudioModel) {
                        if modelStore.lmStudioModels.isEmpty {
                            Text("Loading...").tag("")
                        } else {
                            ForEach(modelStore.lmStudioModels, id: \.self) { Text($0) }
                        }
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
                GroupBox(label: 
                    HStack {
                        Text("Your Input")
                        Spacer()
                        Button(action: { inputText = "" }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Clear Input")
                    }
                ) {
                    TextEditor(text: $inputText)
                        .font(.body)
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                }
                .padding()
                
                GroupBox(label: 
                    HStack {
                        Text("Corrected Output")
                        Spacer()
                        Button(action: {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(correctedText, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .help("Copy Output")
                    }
                ) {
                    TextEditor(text: $correctedText)
                        .font(.body)
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                }
                .padding()
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
            DispatchQueue.main.async {
                if !modelStore.models.contains(appState.selectedGeminiModel) {
                    appState.selectedGeminiModel = modelStore.models.first ?? ""
                }
            }
        }
        .onChange(of: appState.selectedAIProvider) {
            UserDefaults.standard.set(appState.selectedAIProvider, forKey: "selectedAIProvider")
        }
        .onChange(of: selectedPromptID) {
            UserDefaults.standard.set(selectedPromptID?.uuidString, forKey: "selectedPromptID")
        }
        .onChange(of: appState.selectedGeminiModel) {
            UserDefaults.standard.set(appState.selectedGeminiModel, forKey: "selectedGeminiModel")
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

        switch appState.selectedAIProvider {
        case "LM Studio":
            provider = .lmStudio
            apiKey = lmStudioAddress
            modelName = appState.selectedLMStudioModel.isEmpty ? "local-model" : appState.selectedLMStudioModel
        case "Gemini":
            provider = .gemini
            apiKey = geminiAPIKey
            modelName = appState.selectedGeminiModel
        default:
            appState.status = .error(message: "Invalid AI Provider selected.")
            return
        }
        
        guard !apiKey.isEmpty else {
            appState.status = .error(message: "\(appState.selectedAIProvider) API Key or Address is missing.")
            return
        }

        let startTime = Date()

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
            
            let duration = Date().timeIntervalSince(startTime)
            let historyItem = CorrectionHistoryItem(
                originalText: inputText,
                correctedText: correctedText,
                date: Date(),
                duration: duration,
                provider: appState.selectedAIProvider,
                model: modelName
            )
            historyStore.addItem(historyItem)
            
            appState.status = .ready
        } catch {
            appState.status = .error(message: error.localizedDescription)
        }
    }

    private func loadSettings() {
        lmStudioAddress = UserDefaults.standard.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
        geminiAPIKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        
        if let promptIDString = UserDefaults.standard.string(forKey: "selectedPromptID"),
           let promptID = UUID(uuidString: promptIDString),
           promptStore.prompts.contains(where: { $0.id == promptID }) {
            selectedPromptID = promptID
        } else {
            selectedPromptID = promptStore.prompts.first?.id
        }
        
        if appState.selectedGeminiModel.isEmpty {
             appState.selectedGeminiModel = modelStore.models.first ?? ""
        }
    }
}

#Preview {
    CorrectorView()
        .environmentObject(PromptStore())
        .environmentObject(ModelStore())
        .environmentObject(AppState())
}
