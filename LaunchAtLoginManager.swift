import Foundation
import ServiceManagement
import Combine

/// Manages the app's Launch at Login setting using the proper ServiceManagement APIs.
/// - Note: For macOS 13+, uses `SMAppService.loginItem(identifier:)` with your helper's bundle identifier.
///         For earlier versions, falls back to `SMLoginItemSetEnabled`.
@available(macOS 11.0, *)
class LaunchAtLoginManager: ObservableObject {
    /// Update this to your actual login item helper bundle identifier.
    private let helperBundleIdentifier = "com.your.bundle.helper"

    @Published var isEnabled: Bool

    private var cancellable: AnyCancellable?

    init() {
        // Initialize from current system state
        self.isEnabled = Self.currentEnabledState(helperBundleIdentifier: helperBundleIdentifier)

        // Observe changes and apply
        cancellable = $isEnabled
            .removeDuplicates()
            .sink { [weak self] enabled in
                self?.setLaunchAtLogin(enabled: enabled)
            }
    }

    private static func currentEnabledState(helperBundleIdentifier: String) -> Bool {
        if #available(macOS 13.0, *) {
            if let service = try? SMAppService.loginItem(identifier: helperBundleIdentifier) {
                return service.status == .enabled
            } else {
                return false
            }
        } else {
            // There's no direct query API before macOS 13; best-effort: read from UserDefaults if you store it
            // or assume disabled. Here we assume disabled.
            return false
        }
    }

    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                let service = try SMAppService.loginItem(identifier: helperBundleIdentifier)
                if enabled {
                    try service.register()
                } else {
                    try service.unregister()
                }
            } catch {
                print("Failed to update Launch at Login setting: \(error.localizedDescription)")
                // Revert the toggle state if the operation fails
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.isEnabled = Self.currentEnabledState(helperBundleIdentifier: self.helperBundleIdentifier)
                }
            }
        } else {
            // Fallback for macOS 11-12 using SMLoginItemSetEnabled
            let success = SMLoginItemSetEnabled(helperBundleIdentifier as CFString, enabled)
            if !success {
                print("Failed to update Launch at Login setting using SMLoginItemSetEnabled")
                // Revert toggle on failure
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.isEnabled = Self.currentEnabledState(helperBundleIdentifier: self.helperBundleIdentifier)
                }
            }
        }
    }
}
