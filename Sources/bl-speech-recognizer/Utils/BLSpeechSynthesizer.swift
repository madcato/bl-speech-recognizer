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
  func synthesizing(range: NSRange)
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
    buffer.flush(all: isFinished) { text in
      let utterance = if #available(iOS 16.0, macOS 13.0, *) {
        AVSpeechUtterance(ssmlRepresentation: text) ?? AVSpeechUtterance(string: text)
      } else {
        AVSpeechUtterance(string: text)
      }

      utterance.voice = self.voice
      if let rate = rate {
        utterance.rate = rate
      }
      if let pitchMultiplier = pitchMultiplier {
        utterance.pitchMultiplier = pitchMultiplier
      }
      synthesizer?.delegate = self
      synthesizer?.speak(utterance)
      print("[Zeta] Speak: \(text)")
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
  
//  @available(iOS 7.0, *)
//  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
//      print("[Zeta] willSpeakRangeOfSpeechString: \(characterRange)")
//  }

  @available(iOS 17.0, macOS 14.0, *)
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeak marker: AVSpeechSynthesisMarker, utterance: AVSpeechUtterance) {
    print("[Zeta] willSpeak marker: mark: \(marker.mark), byteSampleOffset: \(marker.byteSampleOffset), textRange: \(marker.textRange), phoneme: \(marker.phoneme), bookmarkName: \(marker.bookmarkName)")
    delegate?.synthesizing(range: marker.textRange)
  }
}
