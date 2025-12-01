import Foundation
import AppKit

class SoundManager: NSObject, NSSoundDelegate {
    static let shared = SoundManager()
    
    private var soundQueue: [String] = []
    private var isPlaying = false
    private var cachedSounds: [String: NSSound] = [:]
    
    override init() {
        super.init()
    }
    
    func preloadSounds() {
        let soundNames = ["Tink", "Basso", "Glass"]
        for name in soundNames {
            if let sound = NSSound(named: name) {
                // Cache the sound to keep it in memory
                cachedSounds[name] = sound
                // Setting the delegate here might be useful if we reuse the same instance
                // But NSSound(named:) might return a new instance or shared one.
                // Documentation says: "If a sound with the specified name is already initialized, it is returned."
                // So it returns the same instance.
                sound.delegate = self
            }
        }
    }
    
    func play(named soundName: String) {
        let playSounds = UserDefaults.standard.object(forKey: "playSounds") as? Bool ?? true
        guard playSounds else { return }
        
        DispatchQueue.main.async {
            self.soundQueue.append(soundName)
            self.processQueue()
        }
    }
    
    private func processQueue() {
        guard !isPlaying, !soundQueue.isEmpty else { return }
        
        let soundName = soundQueue.removeFirst()
        
        // Use cached sound if available, otherwise load it
        let sound = cachedSounds[soundName] ?? NSSound(named: soundName)
        
        if let sound = sound {
            // Ensure delegate is set (in case it wasn't cached or delegate was cleared)
            sound.delegate = self
            isPlaying = true
            if !sound.play() {
                // If play failed immediately
                isPlaying = false
                processQueue()
            }
        } else {
            // Skip if sound not found
            processQueue()
        }
    }
    
    func sound(_ sound: NSSound, didFinishPlaying flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.processQueue()
        }
    }
}
