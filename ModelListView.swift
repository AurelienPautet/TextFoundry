import SwiftUI

struct ModelListView: View {
    @EnvironmentObject var modelStore: ModelStore
    @State private var newModelName: String = ""
    @State private var selection: String?

    var body: some View {
        VStack {
            List(selection: $selection) {
                ForEach(modelStore.models, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            
            HStack {
                TextField("Add New Gemini Model Name", text: $newModelName)
                    .onSubmit(addModel)
                Button("Add", action: addModel)
                    .disabled(newModelName.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Manage Gemini Models")
        .toolbar {
            ToolbarItem {
                Button(role: .destructive, action: deleteSelectedModel) {
                    Label("Delete Selected Model", systemImage: "trash")
                }
                .disabled(selection == nil)
            }
        }
    }
    
    private func addModel() {
        modelStore.addModel(newModelName.trimmingCharacters(in: .whitespaces))
        newModelName = ""
    }
    
    private func deleteSelectedModel() {
        if let selection = selection {
            modelStore.deleteModel(named: selection)
            self.selection = nil // Clear selection after delete
        }
    }
}

#Preview {
    ModelListView()
        .environmentObject(ModelStore())
}

