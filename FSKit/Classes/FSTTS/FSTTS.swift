//
//  FSTTS.swift
//  FSAccount
//
//  Created by FudonFuchina on 2019/5/19.
//  Translated to Swift
//

import Foundation
import AVFoundation

public class FSTTS {
    
    private let synthesizer: AVSpeechSynthesizer
    private let voice: AVSpeechSynthesisVoice?
    
    public init() {
        synthesizer = AVSpeechSynthesizer()
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: .mixWithOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        
        voice = AVSpeechSynthesisVoice(language: "zh-CN")
    }
    
    /// 播放语音
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - priority: 优先级，优先级越大值越小，从0开始
    ///   - wait: 同优先级的语音，是否等待前一条播完后继续播，不等待则不会播了
    public func speech(_ text: String, priority: Int = 0, wait: Bool = true) {
        guard !text.isEmpty else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.5
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1
        
        synthesizer.speak(utterance)
    }
}
