import SwiftUI

struct MasterPromptView: View {
    @State private var masterPrompt: String = ""
    private let userDefaultsKey = "masterPrompt"

    var body: some View {
        VStack(alignment: .leading) {
            Text("Master Prompt")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 8)
            
            Text("This prompt will be added before every specific prompt you run. Use it to set the global tone, context, or instructions for the AI.")
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
            
            TextEditor(text: $masterPrompt)
                .font(.body.monospaced())
                .border(Color.gray.opacity(0.2), width: 1)
        }
        .padding()
        .onAppear(perform: loadPrompt)
        .onChange(of: masterPrompt) {
            savePrompt(newValue: masterPrompt)
        }
    }

    private func loadPrompt() {
        masterPrompt = UserDefaults.standard.string(forKey: userDefaultsKey) ?? "You are a helpful assistant."
    }

    private func savePrompt(newValue: String) {
        UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
    }
}

#Preview {
    MasterPromptView()
}
