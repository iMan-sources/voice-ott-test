//
//  ViewController.swift
//  voice-ott-test
//
//  Created by Le Viet Anh on 21/2/25.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private let speakButton: UIButton = {
        let button = UIButton()
        button.setTitle("Speak", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
        
    }()
    
    private let speakButton_1: UIButton = {
        let button = UIButton()
        button.setTitle("Speak_1", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
        
    }()
    
    let speechManager = SpeechService.shared
    var player: AVAudioPlayer?
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var isAudioEngineSetup = false
    private var digitAudioFiles: [Int: AVAudioFile] = [:]
    var components: [AVAudioFile?] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAudioFiles()
        setupAudioEngine()
    }
    
    private func loadAudioFiles() {
        for digit in 0...5 {
            if let url = Bundle.main.url(forResource: "digit_\(digit)", withExtension: "caf") {
                do {
                    digitAudioFiles[digit] = try AVAudioFile(forReading: url)
                    components.append(digitAudioFiles[digit])
                } catch {
                    print("Error loading digit \(digit): \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupAudioEngine() {
        // Setup audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Setup audio engine
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
            isAudioEngineSetup = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func mergeAndPlayAudioFiles(audioFiles: [AVAudioFile]) {
        guard !audioFiles.isEmpty else { return }
        
        // Tạo file tạm thời để lưu kết quả
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mergedFilePath = documentsPath.appendingPathComponent("merged_audio.caf")
        
        // Xóa file cũ nếu tồn tại
        try? FileManager.default.removeItem(at: mergedFilePath)
        
        // Lấy format từ file đầu tiên
        let firstFile = audioFiles[0]
        let fileFormat = firstFile.processingFormat
        
        // Tạo file đầu ra
        guard let outputFile = try? AVAudioFile(
            forWriting: mergedFilePath,
            settings: firstFile.fileFormat.settings,
            commonFormat: fileFormat.commonFormat,
            interleaved: fileFormat.isInterleaved) else {
            print("Không thể tạo file đầu ra")
            return
        }
        
        // Ghép các file
        for file in audioFiles {
            let frameCount = AVAudioFrameCount(file.length)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: frameCount) else {
                continue
            }
            
            do {
                try file.read(into: buffer)
                try outputFile.write(from: buffer)
            } catch {
                print("Lỗi khi ghép file: \(error)")
            }
        }
        
        // Phát file đã ghép
        do {
            player = try AVAudioPlayer(contentsOf: mergedFilePath)
            player?.play()
        } catch {
            print("Lỗi khi phát file đã ghép: \(error)")
        }
    }
    
    func createAndPlayAudioComposition(audioFiles: [AVAudioFile]) {
        let composition = AVMutableComposition()
        
        var currentTime = CMTime.zero
        
        for file in audioFiles {
            // Tạo URL tạm thời cho file
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let tempURL = documentsPath.appendingPathComponent("temp_\(UUID().uuidString).caf")
            
            // Lưu file vào URL tạm thời
            do {
                let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
                try file.read(into: buffer)
                
                let tempFile = try AVAudioFile(forWriting: tempURL, settings: file.fileFormat.settings)
                try tempFile.write(from: buffer)
            } catch {
                print("Lỗi khi lưu file tạm thời: \(error)")
                continue
            }
            
            // Thêm file vào composition
            let asset = AVURLAsset(url: tempURL)
            let duration = asset.duration
            
            guard let audioTrack = composition.addMutableTrack(
                withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                continue
            }
            
            do {
                try audioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: duration),
                    of: asset.tracks(withMediaType: .audio)[0],
                    at: currentTime
                )
                
                // Cập nhật thời gian hiện tại
                currentTime = CMTimeAdd(currentTime, duration)
            } catch {
                print("Lỗi khi thêm track: \(error)")
            }
            
            // Xóa file tạm thời
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // Tạo player item từ composition
        let playerItem = AVPlayerItem(asset: composition)
        let player = AVPlayer(playerItem: playerItem)
        
        // Phát
        player.play()
    }
    
    func playAudioSequence(audioFiles: [AVAudioFile]) {
        guard !audioFiles.isEmpty else { 
            print("No audio files to play")
            return 
        }
        
        // Make sure audio engine is running
        if !isAudioEngineSetup {
            setupAudioEngine()
        }
        
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                print("Failed to start audio engine: \(error)")
                return
            }
        }
        
        // Stop any current playback
        if playerNode.isPlaying {
            playerNode.stop()
        }
        
        // Tạo buffer cho tất cả các file và ghép chúng lại
        let outputFormat = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        let crossfadeDuration: AVAudioFrameCount = 1000 // Số frame cho crossfade
        
        // Tạo buffer đủ lớn để chứa tất cả các file
        var totalFrames: AVAudioFrameCount = 0
        var fileBuffers: [(AVAudioPCMBuffer, AVAudioFrameCount)] = []
        
        // Đọc tất cả các file vào buffer
        for file in audioFiles {
            let fileFormat = file.processingFormat
            let frameCount = AVAudioFrameCount(file.length)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: frameCount) else {
                print("Không thể tạo buffer cho file")
                continue
            }
            
            do {
                try file.read(into: buffer)
                fileBuffers.append((buffer, frameCount))
                totalFrames += frameCount
            } catch {
                print("Lỗi khi đọc file: \(error)")
            }
        }
        
        // Tạo buffer đầu ra
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, 
                                                 frameCapacity: totalFrames) else {
            print("Không thể tạo buffer đầu ra")
            return
        }
        
        // Ghép các buffer lại với nhau
        var currentFrame: AVAudioFrameCount = 0
        
        for (i, (buffer, frameCount)) in fileBuffers.enumerated() {
            // Convert buffer nếu cần
            let convertedBuffer: AVAudioPCMBuffer
            if buffer.format != outputFormat {
                guard let converter = AVAudioConverter(from: buffer.format, to: outputFormat),
                      let tempBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, 
                                                       frameCapacity: frameCount) else {
                    continue
                }
                
                var error: NSError?
                let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                    outStatus.pointee = AVAudioConverterInputStatus.haveData
                    return buffer
                }
                
                converter.convert(to: tempBuffer, error: &error, withInputFrom: inputBlock)
                if let error = error {
                    print("Lỗi chuyển đổi: \(error)")
                    continue
                }
                
                convertedBuffer = tempBuffer
            } else {
                convertedBuffer = buffer
            }
            
            // Copy dữ liệu từ buffer hiện tại vào buffer đầu ra
            for channel in 0..<Int(outputFormat.channelCount) {
                if let src = convertedBuffer.floatChannelData?[channel],
                   let dst = outputBuffer.floatChannelData?[channel] {
                    
                    // Copy dữ liệu
                    for frame in 0..<frameCount {
                        dst[Int(currentFrame + frame)] = src[Int(frame)]
                    }
                    
                    // Áp dụng crossfade nếu không phải file đầu tiên
                    if i > 0 && currentFrame > 0 {
                        let fadeDuration = min(crossfadeDuration, frameCount, currentFrame)
                        
                        for frame in 0..<fadeDuration {
                            let fadeInFactor = Float(frame) / Float(fadeDuration)
                            let fadeOutFactor = 1.0 - fadeInFactor
                            
                            // Crossfade
                            dst[Int(currentFrame + frame)] = 
                                dst[Int(currentFrame + frame)] * fadeInFactor + 
                                dst[Int(currentFrame - fadeDuration + frame)] * fadeOutFactor
                        }
                    }
                }
            }
            
            currentFrame += frameCount
        }
        
        // Cập nhật frameLength
        outputBuffer.frameLength = currentFrame
        
        // Phát buffer đã ghép
        playerNode.scheduleBuffer(outputBuffer, at: nil, options: .interrupts) {
            print("Đã phát xong tất cả âm thanh")
        }
        
        playerNode.play()
    }
    
    @objc func speakOut(_ sender: UIButton) {
        speechManager.speak(text: "01234")
//        let audioFilesToPlay = components.compactMap { $0 }
//        mergeAndPlayAudioFiles(audioFiles: audioFilesToPlay)
    }
    
    @objc func speakIn(_ sender: UIButton) {
        let audioFilesToPlay = components.compactMap { $0 }
        mergeAndPlayAudioFiles(audioFiles: audioFilesToPlay)
    }
    
    private func setupUI() {
        view.addSubview(speakButton)
        view.addSubview(speakButton_1)
        speakButton.addTarget(self, action: #selector(speakOut(_:)), for: .touchUpInside)
        speakButton_1.addTarget(self, action: #selector(speakIn(_:)), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            speakButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            speakButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            speakButton.widthAnchor.constraint(equalToConstant: 120),
            speakButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        NSLayoutConstraint.activate([
            speakButton_1.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            speakButton_1.topAnchor.constraint(equalTo: speakButton.bottomAnchor, constant: 20),
            speakButton_1.widthAnchor.constraint(equalToConstant: 120),
            speakButton_1.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    
}


