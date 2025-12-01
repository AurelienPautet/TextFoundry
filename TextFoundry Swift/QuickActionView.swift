import SwiftUI

struct QuickActionView: View {
    @EnvironmentObject var promptStore: PromptStore
    @EnvironmentObject var customPromptStore: CustomPromptHistoryStore
    @EnvironmentObject var appState: AppState
    
    @State private var customPromptText: String = ""
    @State private var selectedIndex: Int = -1 // -1 means input field is selected
    @State private var eventMonitor: Any?
    @FocusState private var isInputFocused: Bool
    
    var onSelect: (QuickActionSelection) -> Void
    var onCancel: () -> Void
    
    // Computed list of items
    private var recentPrompts: [CustomPromptHistoryItem] {
        if customPromptText.isEmpty {
            return Array(customPromptStore.history.prefix(2))
        } else {
            return customPromptStore.history.filter { $0.content.localizedCaseInsensitiveContains(customPromptText) }
        }
    }
    
    private var savedPrompts: [Prompt] {
        if customPromptText.isEmpty {
            return promptStore.prompts
        } else {
            return promptStore.prompts.filter { 
                $0.name.localizedCaseInsensitiveContains(customPromptText) || 
                $0.content.localizedCaseInsensitiveContains(customPromptText)
            }
        }
    }
    
    private var totalCount: Int {
        recentPrompts.count + savedPrompts.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header & Input
            VStack(spacing: 12) {
                HStack {
                    Image("MenuBarIcon_Busy")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.accentColor)
                    Text("TextFoundry")
                        .font(.headline)
                    Spacer()
                    Text("Esc to cancel")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                TextField("Type a custom prompt or search one", text: $customPromptText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .focused($isInputFocused)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedIndex == -1 ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .onSubmit {
                        handleSelection()
                    }
                    .onChange(of: customPromptText) { _, _ in
                        selectedIndex = -1
                    }
                    .focused($isInputFocused) // Bind the focus state
            }
            .padding()
            .background(Color.clear)
            
            // Info Section
            VStack(spacing: 8) {
                HStack {
                    Label(appState.selectedAIProvider, systemImage: "cpu")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Label(getSelectedModel(), systemImage: "cube")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Recent Prompts Section
                        if !recentPrompts.isEmpty {
                            SectionHeader(title: "Recent")
                            ForEach(Array(recentPrompts.enumerated()), id: \.element.id) { index, item in
                                ListItemView(
                                    title: item.content,
                                    isSelected: selectedIndex == index,
                                    isCustom: true
                                )
                                .onTapGesture {
                                    selectedIndex = index
                                    handleSelection()
                                }
                                .id(index)
                            }
                        }
                        
                        // Saved Prompts Section
                        if !savedPrompts.isEmpty {
                            SectionHeader(title: "Saved")
                            ForEach(Array(savedPrompts.enumerated()), id: \.element.id) { index, prompt in
                                let globalIndex = index + recentPrompts.count
                                ListItemView(
                                    title: prompt.name,
                                    isSelected: selectedIndex == globalIndex,
                                    isCustom: false
                                )
                                .onTapGesture {
                                    selectedIndex = globalIndex
                                    handleSelection()
                                }
                                .id(globalIndex)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(height: min(CGFloat(totalCount * 44 + (recentPrompts.isEmpty ? 0 : 30) + (savedPrompts.isEmpty ? 0 : 30)), 300))
                .onChange(of: selectedIndex) {
                    withAnimation {
                        proxy.scrollTo(selectedIndex, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 400)
        .background(EffectView(material: .popover, blendingMode: .behindWindow))
        .cornerRadius(12)
        .onAppear {
            setupEventMonitor()
            // Delay focus to ensure window is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
        .onDisappear {
            // Critical: Remove the event monitor to prevent memory leaks and duplicate event handling
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 126: // Up arrow
                if selectedIndex > -1 {
                    selectedIndex -= 1
                    return nil // Consume event
                }
                return event
            case 125: // Down arrow
                if selectedIndex < totalCount - 1 {
                    selectedIndex += 1
                    return nil // Consume event
                }
                return event
            case 36: // Enter
                if selectedIndex != -1 {
                    handleSelection()
                    return nil
                }
                return event
            case 53: // Esc
                onCancel()
                return nil
            default:
                return event
            }
        }
    }
    
    private func handleSelection() {
        if selectedIndex == -1 {
            if !customPromptText.isEmpty {
                onSelect(.customPrompt(customPromptText))
            }
        } else {
            if selectedIndex < recentPrompts.count {
                let item = recentPrompts[selectedIndex]
                onSelect(.customPrompt(item.content))
            } else {
                let savedIndex = selectedIndex - recentPrompts.count
                if savedIndex < savedPrompts.count {
                    let prompt = savedPrompts[savedIndex]
                    onSelect(.savedPrompt(prompt.id))
                }
            }
        }
    }
    
    private func getSelectedModel() -> String {
        switch appState.selectedAIProvider {
        case "Gemini": return appState.selectedGeminiModel
        case "OpenAI": return appState.selectedOpenAIModel
        case "LM Studio": return appState.selectedLMStudioModel
        case "xAI Grok": return appState.selectedGrokModel
        default: return "Unknown"
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

struct ListItemView: View {
    let title: String
    let isSelected: Bool
    let isCustom: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isCustom ? "clock" : "doc.text")
                .foregroundColor(isSelected ? .white : .secondary)
                .font(.caption)
            Text(title)
                .font(.body)
                .lineLimit(1)
            Spacer()
            if isSelected {
                Image(systemName: "return")
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor : Color.clear)
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(6)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
}

// Helper for visual effect background
struct EffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
