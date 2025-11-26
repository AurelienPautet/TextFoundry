import SwiftUI

struct PromptManagerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var promptStore: PromptStore

    @State private var showingAddEditPromptSheet = false
    @State private var promptToEdit: Prompt?

    var body: some View {
        VStack {
            List {
                ForEach(promptStore.prompts) { prompt in
                    Text(prompt.name)
                        .onTapGesture {
                            promptToEdit = prompt
                            showingAddEditPromptSheet = true
                        }
                }
                .onDelete(perform: promptStore.deletePrompt)
            }
            .navigationTitle("Manage Prompts")

            HStack {
                Button("Add Prompt") {
                    promptToEdit = nil // No prompt to edit, so adding a new one
                    showingAddEditPromptSheet = true
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
        .sheet(isPresented: $showingAddEditPromptSheet) {
            AddEditPromptSheet(promptToEdit: $promptToEdit)
                .environmentObject(promptStore)
        }
    }
}

// New struct for Add/Edit Prompt Sheet (moved outside PromptManagerView)
struct AddEditPromptSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var promptStore: PromptStore
    
    @Binding var promptToEdit: Prompt?

    @State private var name: String = ""
    @State private var content: String = ""

    var isEditing: Bool { promptToEdit != nil }

    var body: some View {
        VStack {
            Form {
                TextField("Prompt Name", text: $name)
                TextEditor(text: $content)
                    .frame(minHeight: 100)
                    .border(Color.gray.opacity(0.3), width: 1)
                    .cornerRadius(5)
            }
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button(isEditing ? "Update" : "Add") {
                    if let prompt = promptToEdit {
                        promptStore.updatePrompt(id: prompt.id, name: name, content: content)
                    } else {
                        let newPrompt = Prompt(name: name, content: content)
                        promptStore.addPrompt(newPrompt)
                    }
                    dismiss()
                }
            }
            .padding()
        }
        .onAppear {
            if let prompt = promptToEdit {
                name = prompt.name
                content = prompt.content
            }
        }
        .padding()
        .frame(minWidth: 300, minHeight: 250)
        .navigationTitle(isEditing ? "Edit Prompt" : "Add Prompt")
    }
}


#Preview {
    PromptManagerView()
        .environmentObject(PromptStore())
}
