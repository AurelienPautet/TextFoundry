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
    let aiProviders = ["Gemini", "LM Studio", "OpenAI", "xAI Grok"]
    
    private var isBusy: Bool {
        if case .busy = appState.status { return true }
        return false
    }
    
    private var errorMessage: String {
        if case .error(let message) = appState.status { return message }
        return ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Configuration Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configuration")
                        .font(.headline)
                    
                    HStack(alignment: .top, spacing: 20) {
                        // Provider Column
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Provider")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Picker("Provider", selection: $appState.selectedAIProvider) {
                                ForEach(aiProviders, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Model Column
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Model")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            if appState.selectedAIProvider == "Gemini" {
                                Picker("Model", selection: $appState.selectedGeminiModel) {
                                    ForEach(modelStore.models, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                            } else if appState.selectedAIProvider == "LM Studio" {
                                Picker("Model", selection: $appState.selectedLMStudioModel) {
                                    if !modelStore.lmStudioModels.isEmpty {
                                        ForEach(modelStore.lmStudioModels, id: \.self) { Text($0) }
                                    } else {
                                        Text("No models found").tag("")
                                    }
                                }
                                .pickerStyle(.menu)
                            } else if appState.selectedAIProvider == "OpenAI" {
                                Picker("Model", selection: $appState.selectedOpenAIModel) {
                                    ForEach(modelStore.openAIModels, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                            } else if appState.selectedAIProvider == "xAI Grok" {
                                Picker("Model", selection: $appState.selectedGrokModel) {
                                    ForEach(modelStore.grokModels, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Prompt Column
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prompt")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            Picker("Prompt", selection: $selectedPromptID) {
                                Text("Select Prompt").tag(nil as UUID?)
                                ForEach(promptStore.prompts) { prompt in
                                    Text(prompt.name).tag(prompt.id as UUID?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                
                // Input & Output Side-by-Side
                HStack(alignment: .top, spacing: 16) {
                    // Input Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Your Input")
                                .font(.headline)
                            Spacer()
                            Button(action: { inputText = "" }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .help("Clear Input")
                        }
                        
                        TextEditor(text: $inputText)
                            .font(.body)
                            .frame(minHeight: 300)
                            .scrollContentBackground(.hidden)
                            .border(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity)
                    
                    // Output Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Corrected Output")
                                .font(.headline)
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
                        
                        TextEditor(text: $correctedText)
                            .font(.body)
                            .frame(minHeight: 300)
                            .scrollContentBackground(.hidden)
                            .border(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                        
                        if let stats = appState.lastRunStats {
                            Divider()
                            HStack(spacing: 12) {
                                Label(String(format: "%.2fs", stats.duration), systemImage: "stopwatch")
                                
                                if let ttft = stats.timeToFirstToken {
                                    Label(String(format: "TTFT: %.2fs", ttft), systemImage: "bolt")
                                }
                                
                                if let tokens = stats.tokenCount {
                                    Label("\(tokens) toks", systemImage: "text.quote")
                                }
                                
                                if let tps = stats.tokensPerSecond {
                                    Label(String(format: "%.1f t/s", tps), systemImage: "speedometer")
                                }
                                
                                if let retries = stats.retryCount, retries > 0 {
                                    Label("\(retries) retry", systemImage: "arrow.clockwise")
                                        .foregroundColor(.orange)
                                }
                                Spacer()
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity)
                }
                
                // Error/Status Card
                if !errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Action Button
                HStack {
                    if isBusy {
                        ProgressView()
                            .controlSize(.regular)
                    }
                    
                    Button(action: { Task { await runCorrection() } }) {
                        if isBusy {
                            HStack {
                                Text("Processing...")
                                    .frame(maxWidth: .infinity)
                            }
                        } else {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Correct Text")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isBusy || selectedPromptID == nil)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .padding()
        }
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
        if isBusy { return }
        appState.status = .busy
        SoundManager.shared.play(named: "Tink")

        guard !inputText.isEmpty else {
            appState.status = .error(message: "Input text cannot be empty.")
            SoundManager.shared.play(named: "Basso")
            return
        }

        guard let selectedPrompt = promptStore.prompts.first(where: { $0.id == selectedPromptID }) else {
            appState.status = .error(message: "Please select a prompt.")
            SoundManager.shared.play(named: "Basso")
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
        case "OpenAI":
            provider = .openAI
            apiKey = UserDefaults.standard.string(forKey: "openAIAPIKey") ?? ""
            modelName = appState.selectedOpenAIModel
        case "xAI Grok":
            provider = .grok
            apiKey = UserDefaults.standard.string(forKey: "grokAPIKey") ?? ""
            modelName = appState.selectedGrokModel
        default:
            appState.status = .error(message: "Invalid AI Provider selected.")
            SoundManager.shared.play(named: "Basso")
            return
        }
        
        guard !apiKey.isEmpty else {
            appState.status = .error(message: "\(appState.selectedAIProvider) API Key or Address is missing.")
            SoundManager.shared.play(named: "Basso")
            return
        }

        let startTime = Date()

        do {
            let masterPrompt = UserDefaults.standard.string(forKey: "masterPrompt") ?? ""
            let combinedSystemPrompt = "\(masterPrompt)\n\n\(selectedPrompt.content)"

            let response = try await APIService.shared.sendPrompt(
                to: provider,
                systemPrompt: combinedSystemPrompt,
                userPrompt: inputText,
                apiKey: apiKey,
                modelName: modelName
            )
            
            correctedText = response.text
            
            let duration = Date().timeIntervalSince(startTime)
            let tps = duration > 0 ? Double(response.tokenCount) / duration : 0
            
            let historyItem = CorrectionHistoryItem(
                originalText: inputText,
                correctedText: correctedText,
                date: Date(),
                duration: duration,
                provider: appState.selectedAIProvider,
                model: modelName,
                timeToFirstToken: response.timeToFirstToken,
                tokenCount: response.tokenCount,
                tokensPerSecond: tps,
                retryCount: response.retryCount,
                promptTitle: selectedPrompt.name
            )
            historyStore.addItem(historyItem)
            appState.lastRunStats = historyItem
            
            appState.status = .ready
            SoundManager.shared.play(named: "Glass")
        } catch {
            appState.status = .error(message: error.localizedDescription)
            SoundManager.shared.play(named: "Basso")
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
