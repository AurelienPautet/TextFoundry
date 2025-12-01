import Foundation
import SwiftUI

struct UpdateInfo: Codable {
    let version: String
    let downloadURL: String
    let releaseNotes: String
}

class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    
    @Published var isUpdateAvailable: Bool = false
    @Published var latestVersion: String = ""
    @Published var updateInfo: UpdateInfo?
    
    // REPLACE THIS WITH YOUR ACTUAL WEBSITE URL
    private let versionURL = URL(string: "https://textfoundry.pautet.net/version.json")!
    
    func checkForUpdates(isUserInitiated: Bool = false) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: versionURL)
                let info = try JSONDecoder().decode(UpdateInfo.self, from: data)
                
                DispatchQueue.main.async {
                    self.compareVersions(info: info, isUserInitiated: isUserInitiated)
                }
            } catch {
                print("Failed to check for updates: \(error)")
                if isUserInitiated {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Update Check Failed"
                        alert.informativeText = "Could not connect to the update server. Please check your internet connection."
                        alert.alertStyle = .warning
                        alert.runModal()
                    }
                }
            }
        }
    }
    
    private func compareVersions(info: UpdateInfo, isUserInitiated: Bool) {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
        
        if info.version.compare(currentVersion, options: .numeric) == .orderedDescending {
            // New version available
            self.isUpdateAvailable = true
            self.latestVersion = info.version
            self.updateInfo = info
            
            let alert = NSAlert()
            alert.messageText = "New Version Available"
            alert.informativeText = "TextFoundry \(info.version) is available.\n\n\(info.releaseNotes)\n\nYou are currently using version \(currentVersion)."
            alert.addButton(withTitle: "Download")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: info.downloadURL) {
                    NSWorkspace.shared.open(url)
                }
            }
        } else if isUserInitiated {
            // No update available (only show if user clicked the button)
            let alert = NSAlert()
            alert.messageText = "You're Up to Date"
            alert.informativeText = "TextFoundry \(currentVersion) is the latest version."
            alert.runModal()
        }
    }
}
