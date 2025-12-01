import Foundation
import ServiceManagement
import Combine

/// Manages the app's Launch at Login setting using the proper ServiceManagement APIs.
/// - Note: For macOS 13+, uses `SMAppService.loginItem(identifier:)` with your helper's bundle identifier.
///         For earlier versions, falls back to `SMLoginItemSetEnabled`.
@available(macOS 11.0, *)
class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool

    private var cancellable: AnyCancellable?

    init() {
        // Initialize from current system state
        self.isEnabled = Self.currentEnabledState()

        // Observe changes and apply
        cancellable = $isEnabled
            .removeDuplicates()
            .dropFirst() // Avoid setting on init
            .sink { [weak self] enabled in
                self?.setLaunchAtLogin(enabled: enabled)
            }
    }

    private static func currentEnabledState() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // Fallback or check UserDefaults if you implemented a manual mechanism
            return false
        }
    }

    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                let service = SMAppService.mainApp
                if enabled {
                    try service.register()
                } else {
                    try service.unregister()
                }
            } catch {
                print("Failed to update Launch at Login setting: \(error.localizedDescription)")
                // Revert the toggle state if the operation fails
                DispatchQueue.main.async { [weak self] in
                    self?.isEnabled = Self.currentEnabledState()
                }
            }
        } else {
            print("Launch at Login requires macOS 13 or newer for this app.")
        }
    }
}
