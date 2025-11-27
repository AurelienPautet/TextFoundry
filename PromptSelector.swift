import SwiftUI

struct PromptSelector: View {
    @Binding var selection: UUID?
    @Binding var text: String
    @EnvironmentObject var promptStore: PromptStore
    @EnvironmentObject var customPromptStore: CustomPromptHistoryStore
    
    @State private var isShowingSuggestions = false
    @FocusState private var isFocused: Bool
    @State private var textFieldSize: CGSize = .zero
    
    var body: some View {
        TextField("Type a custom prompt or search...", text: $text)
            .textFieldStyle(.roundedBorder)
            .focused($isFocused)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { textFieldSize = geo.size }
                        .onChange(of: geo.size) { _, newSize in textFieldSize = newSize }
                }
            )
            .onChange(of: text) { _, newValue in
                isShowingSuggestions = true
                // If the text changes and doesn't match the selected prompt's content, clear the selection
                if let id = selection {
                    if let prompt = promptStore.prompts.first(where: { $0.id == id }), prompt.content != newValue {
                        selection = nil
                    } else if let custom = customPromptStore.history.first(where: { $0.id == id }), custom.content != newValue {
                        selection = nil
                    }
                }
            }
            .onChange(of: isFocused) { _, focused in
                if focused {
                    isShowingSuggestions = true
                } else {
                    // Delay hiding to allow tap on suggestion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isShowingSuggestions = false
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                suggestionsOverlay
            }
            .zIndex(10)
    }
    
    @ViewBuilder
    private var suggestionsOverlay: some View {
        if isShowingSuggestions && !filteredPrompts.isEmpty {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredPrompts, id: \.id) { item in
                        Button(action: {
                            selectPrompt(item)
                        }) {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .foregroundColor(.primary)
                                if !item.subtitle.isEmpty {
                                    Text(item.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        
                        Divider()
                    }
                }
            }
            .frame(width: textFieldSize.width)
            .frame(maxHeight: 200)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(radius: 4)
            .offset(y: textFieldSize.height + 4)
        }
    }
    
    private struct SuggestionItem: Identifiable {
        let id: UUID
        let title: String
        let subtitle: String
        let content: String
        let isCustomHistory: Bool
    }
    
    private var filteredPrompts: [SuggestionItem] {
        var items: [SuggestionItem] = []
        
        // Stored Prompts
        let stored = promptStore.prompts.map {
            SuggestionItem(id: $0.id, title: $0.name, subtitle: $0.content, content: $0.content, isCustomHistory: false)
        }
        items.append(contentsOf: stored)
        
        // Custom History
        let history = customPromptStore.history.map {
            SuggestionItem(id: $0.id, title: $0.content, subtitle: "History", content: $0.content, isCustomHistory: true)
        }
        items.append(contentsOf: history)
        
        if text.isEmpty {
            return items
        }
        
        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(text) ||
            item.subtitle.localizedCaseInsensitiveContains(text)
        }
    }
    
    private func selectPrompt(_ item: SuggestionItem) {
        text = item.content
        selection = item.id
        isShowingSuggestions = false
        isFocused = false
    }
}
