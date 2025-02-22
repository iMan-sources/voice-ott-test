//
//  NotificationSpeechManager.swift
//  voice-ott-test
//
//  Created by Le Viet Anh on 21/2/25.
//

import Foundation
import AVFoundation
import UIKit

final class SpeechService: NSObject {
    // Singleton instance
    static let shared = SpeechService()
    
    private let synthesizer: AVSpeechSynthesizer
    private let audioSession: AVAudioSession
    private var isInitialized = false
    private let voiceCache: NSCache<NSString, AVSpeechSynthesisVoice>
    private let initializationQueue = DispatchQueue(label: "com.speechservice.initialization")
    
    // Configuration constants
    private enum Config {
        static let defaultLanguage = "vi-VN"
        static let fallbackLanguage = "en-US"
        static let preWarmText = " " // Single space for minimal initialization
    }
    
    private override init() {
        synthesizer = AVSpeechSynthesizer()
        audioSession = .sharedInstance()
        voiceCache = NSCache<NSString, AVSpeechSynthesisVoice>()
        super.init()
        
        // Initialize on background thread
        initializationQueue.async { [weak self] in
            self?.initialize()
        }
    }
    
    private func initialize() {
        setupAudioSession()
        synthesizer.delegate = self
        prewarmSynthesizer()
        cacheCommonVoices()
        isInitialized = true
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback,
                                       mode: .spokenAudio,
                                       options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func prewarmSynthesizer() {
        let utterance = AVSpeechUtterance(string: Config.preWarmText)
        utterance.volume = 0.0
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
    
    private func cacheCommonVoices() {
        // Cache commonly used voices
        [Config.defaultLanguage, Config.fallbackLanguage].forEach { language in
            if let voice = AVSpeechSynthesisVoice(language: language) {
                voiceCache.setObject(voice, forKey: language as NSString)
            }
        }
    }
    
    private func getVoice(for language: String) -> AVSpeechSynthesisVoice? {
        // Check cache first
        if let cachedVoice = voiceCache.object(forKey: language as NSString) {
            return cachedVoice
        }
        
        // Try different approaches to get a voice
        let voice = AVSpeechSynthesisVoice(language: language) ??
                   AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.contains(language) }) ??
                   AVSpeechSynthesisVoice(language: Config.fallbackLanguage)
        
        // Cache the result if found
        if let voice = voice {
            voiceCache.setObject(voice, forKey: language as NSString)
        }
        
        return voice
    }
    
    func speak(text: String,
               language: String = Config.defaultLanguage,
               rate: Float = AVSpeechUtteranceDefaultSpeechRate,
               pitchMultiplier: Float = 1.0,
               completion: (() -> Void)? = nil) {
        
        // Ensure initialization is complete
        if !isInitialized {
            initializationQueue.async { [weak self] in
                self?.initialize()
                self?.performSpeech(text: text, language: language, rate: rate, pitchMultiplier: pitchMultiplier, completion: completion)
            }
            return
        }
        
        performSpeech(text: text, language: language, rate: rate, pitchMultiplier: pitchMultiplier, completion: completion)
    }
    
    private func performSpeech(text: String,
                             language: String,
                             rate: Float,
                             pitchMultiplier: Float,
                             completion: (() -> Void)?) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = getVoice(for: language)
        utterance.rate = rate
        utterance.pitchMultiplier = pitchMultiplier
        utterance.volume = 1.0
        
        if let completion = completion {
            NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                 object: nil,
                                                 queue: .main) { [weak self] _ in
                self?.stopSpeaking()
                completion()
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.synthesizer.speak(utterance)
        }
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        NotificationCenter.default.removeObserver(self,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
    }
}
