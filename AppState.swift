import Foundation
import Combine

enum AppStatus {
    case ready
    case busy
    case error(message: String)
}

class AppState: ObservableObject {
    @Published var status: AppStatus = .ready
}
