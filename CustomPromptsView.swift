import SwiftUI

struct CustomPromptsView: View {
    @EnvironmentObject var customPromptStore: CustomPromptHistoryStore
    @EnvironmentObject var promptStore: PromptStore
    @State private var showingSaveSheet = false
    @State private var selectedPromptContent: String = ""
    @State private var newPromptName: String = ""
    
    var body: some View {
        List {
            if customPromptStore.history.isEmpty {
                Text("No custom prompts history yet.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(customPromptStore.history) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.content)
                                .font(.body)
                                .lineLimit(2)
                            Text(item.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Save") {
                            selectedPromptContent = item.content
                            newPromptName = ""
                            showingSaveSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: customPromptStore.deletePrompt)
            }
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
