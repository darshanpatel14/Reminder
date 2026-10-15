import Foundation
import AVFoundation
import UIKit

/// Manages In-App Audible Chimes, Spoken Voice Reminders, and Haptics
public final class SoundManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    public static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private override init() {
        super.init()
        configureAudioSession()
    }
    
    /// Configures audio session so sounds play aloud even if hardware mute switch is on
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session configuration error: \(error.localizedDescription)")
        }
    }
    
    /// Plays bundled chime audio through the iPhone speaker
    public func playChime(named name: String = "chime") {
        configureAudioSession()
        
        let soundFilename: String
        switch name.lowercased() {
        case "bell", "zen_bell":
            soundFilename = "bell"
        case "water", "raindrop":
            soundFilename = "water"
        case "singing_bowl":
            soundFilename = "singing_bowl"
        default:
            soundFilename = "chime"
        }
        
        // Trigger gentle haptic tap
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        
        guard let url = Bundle.main.url(forResource: soundFilename, withExtension: "wav") ??
                        Bundle.main.url(forResource: "chime", withExtension: "wav") else {
            // Fallback to system alert sound
            AudioServicesPlaySystemSound(1007)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Audio playback failed: \(error.localizedDescription)")
            AudioServicesPlaySystemSound(1007)
        }
    }
    
    /// Speaks a gentle voice reminder (e.g. "Time to drink water and roll your shoulders back")
    public func speakVoicePrompt(_ text: String) {
        configureAudioSession()
        guard !text.isEmpty else { return }
        
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9 // slightly slower, calm cadence
        utterance.pitchMultiplier = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        speechSynthesizer.speak(utterance)
    }
}
