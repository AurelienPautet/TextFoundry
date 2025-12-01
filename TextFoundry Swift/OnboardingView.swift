import SwiftUI
import ApplicationServices

struct OnboardingView: View {
    var onFinished: () -> Void
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var timer: Timer?
    
    let pages = [
        OnboardingPageData(image: "wand.and.stars", title: "Welcome to TextFoundry", description: "Your personal AI assistant for correcting, translating, and improving text across your Mac."),
        OnboardingPageData(image: "hand.raised.fill", title: "Permissions", description: "TextFoundry needs Accessibility access to read your selection and paste corrections."),
        OnboardingPageData(image: "keyboard", title: "Quick Actions", description: "Use the global hotkey (default: ⌘+Shift+E) to bring up the Quick Action panel anywhere."),
        OnboardingPageData(image: "text.quote", title: "Custom Prompts", description: "Create your own prompts for specific tasks and access them instantly via Quick Actions."),
        OnboardingPageData(image: "gearshape.fill", title: "Setup Required", description: "To start using the app, you need to configure your API keys. Click 'Get Started' to go to Settings now.")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            VStack {
                let page = pages[currentPage]
                Image(systemName: page.image)
                    .font(.system(size: 70))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 20)
                    .frame(height: 120)
                
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Text(page.description)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
                    .frame(height: 80, alignment: .top)
                
                if page.title == "Permissions" {
                    if appState.isAccessibilityGranted {
                        Text("Permission Granted")
                            .font(.headline)
                            .foregroundColor(.green)
                            .padding(.top, 10)
                    } else {
                        VStack(spacing: 10) {
                            Button("Grant Access") {
                                let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
                                AXIsProcessTrustedWithOptions(options)
                                // Open System Settings
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Text("If the app doesn't appear in the list automatically, please drag the TextFoundry app icon from your Applications folder into the list manually.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            Button("Open Applications Folder") {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: "/Applications")
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .id(currentPage) // Triggers transition
            
            // Controls
            HStack {
                // Page Indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(pages[currentPage].title == "Permissions" && !appState.isAccessibilityGranted)
                } else {
                    Button("Get Started") {
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        appState.selectedPanel = .settings
                        onFinished()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(30)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 600, height: 450)
        .onAppear {
            // Start timer to check accessibility
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
                let accessEnabled = AXIsProcessTrustedWithOptions(options)
                if appState.isAccessibilityGranted != accessEnabled {
                    appState.isAccessibilityGranted = accessEnabled
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

struct OnboardingPageData {
    let image: String
    let title: String
    let description: String
}
