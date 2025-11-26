import SwiftUI

struct QuickActionView: View {
    @EnvironmentObject var promptStore: PromptStore
    @State private var selectedIndex: Int = 0
    var onSelect: (UUID) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Search (Placeholder for now)
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.accentColor)
                Text("Choose a Prompt")
                    .font(.headline)
                Spacer()
                Text("Esc to cancel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(promptStore.prompts.enumerated()), id: \.element.id) { index, prompt in
                            HStack {
                                Text(prompt.name)
                                    .font(.body)
                                Spacer()
                                if index == selectedIndex {
                                    Image(systemName: "return")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(index == selectedIndex ? Color.accentColor : Color.clear)
                            .foregroundColor(index == selectedIndex ? .white : .primary)
                            .cornerRadius(6)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .id(index)
                            .onTapGesture {
                                selectedIndex = index
                                onSelect(prompt.id)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(height: min(CGFloat(promptStore.prompts.count * 44), 300))
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            selectedIndex = 0
        }
        // Keyboard handling
        .background(KeyHandler(selectedIndex: $selectedIndex, maxIndex: promptStore.prompts.count, onSelect: {
            if promptStore.prompts.indices.contains(selectedIndex) {
                onSelect(promptStore.prompts[selectedIndex].id)
            }
        }, onCancel: onCancel))
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

// Invisible view to handle keyboard events
struct KeyHandler: NSViewRepresentable {
    @Binding var selectedIndex: Int
    var maxIndex: Int
    var onSelect: () -> Void
    var onCancel: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onKeyDown = { event in
            switch event.keyCode {
            case 126: // Up arrow
                if selectedIndex > 0 { selectedIndex -= 1 }
                return true
            case 125: // Down arrow
                if selectedIndex < maxIndex - 1 { selectedIndex += 1 }
                return true
            case 36: // Enter
                onSelect()
                return true
            case 53: // Esc
                onCancel()
                return true
            default:
                return false
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? KeyView {
            view.onKeyDown = { event in
                switch event.keyCode {
                case 126: // Up arrow
                    if selectedIndex > 0 { selectedIndex -= 1 }
                    return true
                case 125: // Down arrow
                    if selectedIndex < maxIndex - 1 { selectedIndex += 1 }
                    return true
                case 36: // Enter
                    onSelect()
                    return true
                case 53: // Esc
                    onCancel()
                    return true
                default:
                    return false
                }
            }
        }
    }
    
    class KeyView: NSView {
        var onKeyDown: ((NSEvent) -> Bool)?
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            if let onKeyDown = onKeyDown, onKeyDown(event) {
                return
            }
            super.keyDown(with: event)
        }
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }
    }
}
