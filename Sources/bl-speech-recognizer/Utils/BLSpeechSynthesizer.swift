//
//  BLSpeechSynthesizer.swift
//  Marla
//
//  Created by Daniel Vela Angulo on 22/07/2019.
//  Copyright © 2019 veladan. All rights reserved.
//

import AVFoundation

public struct Voice: Hashable {
  public var language: String
  public var identifier: String
  public var name: String
  public var rate: Float? = nil
  public var pitchMultiplier: Float? = nil
}

protocol BLSpeechSynthesizerDelegate: AnyObject {
  func synthesizerStarted()
  func synthesizerFinished()
}

class BLSpeechSynthesizer: NSObject, @unchecked Sendable {
  private var synthesizer: AVSpeechSynthesizer? = nil
  weak var delegate: BLSpeechSynthesizerDelegate?
  private var buffer = BLResponseStringBuffer(minLength: 10)
  private var isFinished = false
  private var voice: AVSpeechSynthesisVoice!
  private var rate: Float?
  private var pitchMultiplier: Float?
  
  var isSpeaking: Bool {
    return synthesizer?.isSpeaking ?? false
  }
  
  init(language: String) {
    self.voice = AVSpeechSynthesisVoice(language: language)
  }
  
  init(voice: Voice) {
    let voiceIdentifier = voice.identifier
    self.rate = voice.rate
    self.pitchMultiplier = voice.pitchMultiplier
    self.voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier)
  }
  
  func stop() {
    synthesizer?.stopSpeaking(at: AVSpeechBoundary.immediate)
    buffer.reset()
  }
  
  func speak(_ str: String, isFinal: Bool) {
    isFinished = isFinal
    buffer.onMessageReceived(text: str)
    internalSpeak()
  }
  
  static func availableVoices() -> [Voice] {
    return AVSpeechSynthesisVoice.speechVoices().map { voice in
      Voice(language: voice.language,
            identifier: voice.identifier,
            name: voice.name)
    }
  }
  
  private func internalSpeak() {
    self.synthesizer = self.synthesizer ?? initializeSynthesizer()
    guard synthesizer?.isSpeaking == false else { return }
    buffer.flush(all: isFinished) { text in
      let utterance = AVSpeechUtterance(string: text)
      utterance.voice = self.voice
      if let rate = rate {
        utterance.rate = rate
      }
      if let pitchMultiplier = pitchMultiplier {
        utterance.pitchMultiplier = pitchMultiplier
      }
      synthesizer?.delegate = self
      synthesizer?.speak(utterance)
    }
  }
  
  private func initializeSynthesizer() -> AVSpeechSynthesizer {
    let synth = AVSpeechSynthesizer()
    #if !os(macOS)
    synth.usesApplicationAudioSession = false
    #endif
    return synth
  }
}

extension BLSpeechSynthesizer: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    delegate?.synthesizerStarted()
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    if isFinished {
      delegate?.synthesizerFinished()
    } else {
      internalSpeak()
    }
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    delegate?.synthesizerFinished()
  }
}
