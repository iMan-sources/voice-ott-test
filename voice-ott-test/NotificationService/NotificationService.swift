//
//  NotificationService.swift
//  NotificationService
//
//  Created by Build ios on 24/2/25.
//

import UserNotifications
import AVFoundation

class NotificationService: UNNotificationServiceExtension, AVSpeechSynthesizerDelegate {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    private var synthesizer: AVSpeechSynthesizer?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        print("🔔 NotificationService - didReceive called")
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        // Initialize synthesizer
        synthesizer = AVSpeechSynthesizer()
        synthesizer?.delegate = self
        
        if let bestAttemptContent = bestAttemptContent {
            print("📝 Notification payload:", request.content.userInfo)
            
            // Get text to speak from notification body
            let textToSpeak = request.content.body
            print("🗣 Will speak:", textToSpeak)
            
            // Configure audio session with options
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, options: [.duckOthers, .mixWithOthers])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                // Create utterance with more specific settings
                let utterance = AVSpeechUtterance(string: textToSpeak)
                utterance.rate = 0.5
                utterance.volume = 1.0
                utterance.pitchMultiplier = 1.0
                utterance.voice = AVSpeechSynthesisVoice(language: "vi-VN") // or your preferred language
                
                print("🎤 Starting speech synthesis...")
                synthesizer?.speak(utterance)
                
                // Extend the wait time to ensure speech completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    print("✅ Delivering notification after delay")
                    self.finishNotification()
                }
                
            } catch {
                print("❌ Audio session error:", error)
                finishNotification()
            }
        }
    }
    
    private func finishNotification() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate Methods
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("📢 Speech started")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("✅ Speech finished")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("❌ Speech cancelled")
    }
    
    override func serviceExtensionTimeWillExpire() {
        print("⚠️ Service extension time will expire")
        if let synthesizer = synthesizer {
            synthesizer.stopSpeaking(at: .immediate)
        }
        finishNotification()
    }

}
