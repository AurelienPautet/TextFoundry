import SwiftUI

// The main view for the "Prompts" panel
struct PromptListView: View {
    @EnvironmentObject var promptStore: PromptStore
    @State private var selection: Prompt.ID?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(promptStore.prompts) { prompt in
                    Text(prompt.name).tag(prompt.id)
                }
                // .onDelete has been removed
            }
            .navigationTitle("Prompts")
            .toolbar {
                ToolbarItem {
                    Button(action: addPrompt) {
                        Label("Add Prompt", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selectedPromptID = selection,
               let index = promptStore.prompts.firstIndex(where: { $0.id == selectedPromptID }) {
                PromptEditorView(prompt: $promptStore.prompts[index])
                    .environmentObject(promptStore) // Pass the store
            } else {
                Text("Select a prompt to edit, or add a new one.")
            }
        }
    }

    private func addPrompt() {
        let newPrompt = Prompt(name: "New Prompt", content: "Your new prompt content here.")
        promptStore.addPrompt(newPrompt)
        selection = newPrompt.id // Select the new prompt
    }
}

// The detail view for editing a single prompt
struct PromptEditorView: View {
    @EnvironmentObject var promptStore: PromptStore
    @Binding var prompt: Prompt

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Prompt Name") {
                TextField("Name", text: $prompt.name)
                    .labelsHidden()
            }
            
            GroupBox("Prompt Content") {
                TextEditor(text: $prompt.content)
                    .frame(minHeight: 200, maxHeight: .infinity)
                    .font(.body.monospaced())
                    .scrollContentBackground(.hidden)
            }
            
            Spacer() // Pushes content to the top
        }
        .padding()
        .navigationTitle(prompt.name)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive, action: deleteCurrentPrompt) {
                    Label("Delete Prompt", systemImage: "trash")
                }
            }
        }
    }
    
    private func deleteCurrentPrompt() {
        promptStore.deletePrompt(id: prompt.id)
    }
}

#Preview {
    PromptListView()
        .environmentObject(PromptStore())
}

