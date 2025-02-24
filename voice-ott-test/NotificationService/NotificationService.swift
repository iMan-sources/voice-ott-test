//
//  NotificationService.swift
//  NotificationService
//
//  Created by Build ios on 24/2/25.
//

import UserNotifications
import AVFoundation

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    private let speech = Speech.shared
    private var hasFinishedNotification = false
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {

            // Get text to speak from notification body
            let textToSpeak = bestAttemptContent.body
            // Use Speech class to handle text-to-speech
            speech.speak(text: textToSpeak, language: "vi-VN", rate: 0.5) { [weak self] in
                print("✅ Speech completed")
                self?.finishNotification()
            }
            
            // Fallback in case speech takes too long
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
                print("⚠️ Fallback: Checking if notification needs delivery")
                self?.finishNotification()
            }
        }
    }
    
    private func finishNotification() {
        guard !hasFinishedNotification else { return }
        hasFinishedNotification = true
        
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        print("⚠️ Service extension time will expire")
        speech.stopSpeaking()
        finishNotification()
    }
}
