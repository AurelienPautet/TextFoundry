import SwiftUI

// The main view for the "Prompts" panel
struct PromptListView: View {
    @EnvironmentObject var promptStore: PromptStore
    @State private var selection: Prompt.ID?
    @State private var searchText: String = ""

    var filteredPrompts: [Prompt] {
        if searchText.isEmpty {
            return promptStore.prompts
        } else {
            return promptStore.prompts.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(filteredPrompts) { prompt in
                    NavigationLink(value: prompt.id) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(prompt.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(prompt.content)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .searchable(text: $searchText, placement: .sidebar)
            .navigationTitle("Prompts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addPrompt) {
                        Label("Add Prompt", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selectedPromptID = selection,
               let index = promptStore.prompts.firstIndex(where: { $0.id == selectedPromptID }) {
                PromptEditorView(prompt: $promptStore.prompts[index])
                    .environmentObject(promptStore)
            } else {
                ContentUnavailableView("Select a Prompt", systemImage: "text.bubble", description: Text("Select a prompt from the list or create a new one."))
            }
        }
    }

    private func addPrompt() {
        let newPrompt = Prompt(name: "New Prompt", content: "")
        promptStore.addPrompt(newPrompt)
        selection = newPrompt.id
    }
}

// The detail view for editing a single prompt
struct PromptEditorView: View {
    @EnvironmentObject var promptStore: PromptStore
    @Binding var prompt: Prompt
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Name Section
                GroupBox(label: Label("Name", systemImage: "tag")) {
                    TextField("Enter prompt name", text: $prompt.name)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .padding(8)
                }
                
                // Content Section
                GroupBox(label: Label("Content", systemImage: "text.alignleft")) {
                    TextEditor(text: $prompt.content)
                        .font(.body.monospaced())
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 100)
                }
                
                // Delete Button
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Label("Delete Prompt", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.top, 10)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(prompt.name)
        .alert("Delete Prompt?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteCurrentPrompt()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(prompt.name)'? This action cannot be undone.")
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

