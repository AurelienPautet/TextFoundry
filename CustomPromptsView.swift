import SwiftUI

struct CustomPromptsView: View {
    @EnvironmentObject var customPromptStore: CustomPromptHistoryStore
    @EnvironmentObject var promptStore: PromptStore
    @State private var showingSaveSheet = false
    @State private var selectedPromptContent: String = ""
    @State private var newPromptName: String = ""
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if customPromptStore.history.isEmpty {
                    Text("No custom prompts history yet.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(customPromptStore.history) { item in
                        CustomPromptCard(item: item) {
                            selectedPromptContent = item.content
                            newPromptName = ""
                            showingSaveSheet = true
                        } onDelete: {
                            customPromptStore.deletePrompt(id: item.id)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Custom Prompts History")
        .sheet(isPresented: $showingSaveSheet) {
            VStack(spacing: 20) {
                Text("Save as New Prompt")
                    .font(.headline)
                
                TextField("Prompt Name", text: $newPromptName)
                    .textFieldStyle(.roundedBorder)
                
                TextEditor(text: $selectedPromptContent)
                    .frame(height: 100)
                    .border(Color.gray.opacity(0.2))
                
                HStack {
                    Button("Cancel") {
                        showingSaveSheet = false
                    }
                    Spacer()
                    Button("Save") {
                        let newPrompt = Prompt(name: newPromptName.isEmpty ? "New Prompt" : newPromptName, content: selectedPromptContent)
                        promptStore.addPrompt(newPrompt)
                        showingSaveSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 400, height: 300)
        }
    }
}

struct CustomPromptCard: View {
    let item: CustomPromptHistoryItem
    let onSave: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.content)
                        .font(.body)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: onSave) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderless)
                    .help("Save as Prompt")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete")
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
