import UIKit
import AVFoundation

#warning("This app has crashed because it attempted to access privacy-sensitive data without a usage description.  The app's Info.plist must contain an NSMicrophoneUsageDescription key with a string value explaining to the user how the app uses this data.")

// Info.plist             Privacy - Microphone Usage Description              This app use the microphone to record audio

// Note: You may need a different AVAudioSession.Mode and a different AVAudioSession.CategoryOptions


class SpeechToAudioFileConverter {
    
    let synthesizer: AVSpeechSynthesizer
    
    init() {
        self.synthesizer = AVSpeechSynthesizer()
    }
    
    var recordingPath:  URL {
        let soundName = "Finally.caf"
        // I've tried numerous file extensions.  .caf was in an answer somewhere else.  I would think it would be
        // .pcm, but that doesn't work either.
        
        // Local Directory
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(soundName)
    }
    
    func saveAVSpeechUtteranceToFile() {
        
        let utterance = AVSpeechUtterance(string: "This is speech to record")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.50
        
        // Only create new file handle if `output` is nil.
        var output: AVAudioFile?
        
        synthesizer.write(utterance) { [self] (buffer: AVAudioBuffer) in
            guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                fatalError("unknown buffer type: \(buffer)")
            }
            if pcmBuffer.frameLength == 0 {
                // Done
                print(recordingPath)
            } else {
                
                do{
                    // this closure is called multiple times. so to save a complete audio, try create a file only for once.
                    if output == nil {
                        try  output = AVAudioFile(
                            forWriting: recordingPath,
                            settings: pcmBuffer.format.settings,
                            commonFormat: pcmBuffer.format.commonFormat,
                            interleaved: false)
                    }
                    try output?.write(from: pcmBuffer)
                }catch {
                    print(error.localizedDescription)
                }
                
            }
            
        }
    }
}
