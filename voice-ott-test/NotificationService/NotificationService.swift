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
    private lazy var speech: Speech = Speech.shared
    private var hasFinishedNotification = false
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        speech.onFinish = {[weak self] in
            self?.finishNotification()
        }
        if let bestAttemptContent = bestAttemptContent {

            // Get text to speak from notification body
            let textToSpeak = bestAttemptContent.body
            // Use Speech class to handle text-to-speech
            speech.speak(text: textToSpeak, language: "vi-VN", rate: 0.5)
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
        speech.stopSpeaking()
        finishNotification()
    }
}
