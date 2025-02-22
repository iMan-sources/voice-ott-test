//
//  ViewController.swift
//  voice-ott-test
//
//  Created by Le Viet Anh on 21/2/25.
//

import UIKit

class ViewController: UIViewController {
    
    private let speakButton: UIButton = {
        let button = UIButton()
        button.setTitle("Speak", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
        
    }()
    
    let speechManager = SpeechService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        
    }
    
    @objc func speakOut(_ sender: UIButton) {
        speechManager.speak(text: "bạn đã nhận được 10000 đồng")
    }
    
    private func setupUI() {
        view.addSubview(speakButton)
        speakButton.addTarget(self, action: #selector(speakOut(_:)), for: .touchUpInside)

        NSLayoutConstraint.activate([
            speakButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            speakButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            speakButton.widthAnchor.constraint(equalToConstant: 120),
            speakButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}

