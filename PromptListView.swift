import SwiftUI

struct PromptListView: View {
    @EnvironmentObject var promptStore: PromptStore
    @State private var searchText: String = ""
    @State private var selectedPromptID: UUID?
    @State private var showAddPrompt = false
    @State private var showMasterPromptEditor = false
    @State private var masterPrompt: String = ""
    private let masterPromptUserDefaultsKey = "masterPrompt"

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
        VStack {
            // Master Prompt Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Master Prompt")
                        .font(.headline)
                    Spacer()
                    Button(action: { showMasterPromptEditor = true }) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)
                }
                
                Text("This prompt will be added before every specific prompt you run.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(masterPrompt)
                    .font(.caption)
                    .textSelection(.enabled)
                    .padding()
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .lineLimit(3)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding()
            
            Divider()
                .padding(.horizontal)
            
            // Prompts Section
            if promptStore.prompts.isEmpty {
                ContentUnavailableView("No Prompts", systemImage: "text.bubble", description: Text("Create your first prompt to get started."))
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Drag and drop to reorder prompts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    List(selection: $selectedPromptID) {
                        ForEach(filteredPrompts) { prompt in
                            PromptRowCard(prompt: prompt, isSelected: selectedPromptID == prompt.id)
                                .tag(prompt.id)
                                .listRowBackground(Color.clear) // Remove default selection background
                                .padding(.vertical, 4)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        promptStore.deletePrompt(id: prompt.id)
                                        if selectedPromptID == prompt.id {
                                            selectedPromptID = nil
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .onDelete(perform: deletePrompts)
                        .onMove(perform: movePrompts)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search prompts")
        .navigationTitle("Prompts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddPrompt = true }) {
                    Label("Add Prompt", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddPrompt) {
            PromptEditorSheet(
                prompt: Prompt(name: "New Prompt", content: ""),
                isNew: true,
                onSave: { newPrompt in
                    promptStore.addPrompt(newPrompt)
                    showAddPrompt = false
                    selectedPromptID = newPrompt.id
                }
            )
        }
        .sheet(isPresented: $showMasterPromptEditor) {
            MasterPromptEditorSheet(masterPrompt: $masterPrompt)
        }
        .onChange(of: selectedPromptID) {
            // Handle opening editor sheet for selected prompt
            if let selectedPromptID = selectedPromptID,
               let _ = promptStore.prompts.firstIndex(where: { $0.id == selectedPromptID }) {
                DispatchQueue.main.async {
                    // Open the editor sheet by triggering a state change
                }
            }
        }
        .onAppear {
            masterPrompt = UserDefaults.standard.string(forKey: masterPromptUserDefaultsKey) ?? "You are a text correction assistant. Respond ONLY with the corrected text, preserving all original formatting (spacing, line breaks, punctuation style, capitalization). Do not include explanations, comments, or any text other than the corrected version."
        }
    }
    
    private func deletePrompts(at offsets: IndexSet) {
        promptStore.deletePrompt(at: offsets)
        selectedPromptID = nil
    }
    
    private func movePrompts(from source: IndexSet, to destination: Int) {
        if searchText.isEmpty {
            promptStore.movePrompt(from: source, to: destination)
        }
    }
}

struct PromptRowCard: View {
    let prompt: Prompt
    let isSelected: Bool
    @State private var showEditor = false
    @EnvironmentObject var promptStore: PromptStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(prompt.content)
                        .lineLimit(2)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.up")
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if isSelected {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text(prompt.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            ClipboardManager.write(prompt.content)
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: { showEditor = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        Button(role: .destructive, action: {
                            promptStore.deletePrompt(id: prompt.id)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
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
        .sheet(isPresented: $showEditor) {
            PromptEditorSheet(
                prompt: prompt,
                isNew: false,
                onSave: { updatedPrompt in
                    if let index = promptStore.prompts.firstIndex(where: { $0.id == updatedPrompt.id }) {
                        promptStore.prompts[index] = updatedPrompt
                    }
                }
            )
        }
    }
}

struct PromptEditorSheet: View {
    @State var prompt: Prompt
    let isNew: Bool
    let onSave: (Prompt) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(isNew ? "New Prompt" : "Edit Prompt")
                    .font(.headline)
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderless)
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Name")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    TextField("Prompt name", text: $prompt.name)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading) {
                    Text("Content")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    TextEditor(text: $prompt.content)
                        .frame(minHeight: 150)
                        .font(.body.monospaced())
                        .scrollContentBackground(.hidden)
                        .border(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                }
                
                Spacer()
            }
            .padding()
            
            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save") {
                    onSave(prompt)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct MasterPromptEditorSheet: View {
    @Binding var masterPrompt: String
    @Environment(\.dismiss) var dismiss
    private let userDefaultsKey = "masterPrompt"
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Master Prompt")
                    .font(.headline)
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderless)
            }
            .padding()
            
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Warning: Advanced Feature")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                Text("This prompt will be added before every specific prompt you run. Only modify this if you understand how system prompts affect AI behavior.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            VStack(alignment: .leading) {
                Text("Content")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                TextEditor(text: $masterPrompt)
                    .font(.body.monospaced())
                    .scrollContentBackground(.hidden)
                    .border(Color.gray.opacity(0.2))
                    .cornerRadius(6)
            }
            .padding()
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save") {
                    UserDefaults.standard.set(masterPrompt, forKey: userDefaultsKey)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    PromptListView()
        .environmentObject(PromptStore())
}

