//
//  BLSpeechSynthesizer.swift
//  Marla
//
//  Created by Daniel Vela Angulo on 22/07/2019.
//  Copyright © 2019 veladan. All rights reserved.
//

import AVFoundation
import AVFAudio

@available(macOS 10.15, *)
public enum VoiceGender: String, CaseIterable {
  case male = "Male"
  case female = "Female"
  case unspecified = "Unspecified"
}

public enum VoiceQuality: String, CaseIterable {
  case `default` = "Default"
  case enhanced = "Enhanced"
  case premium = "Premium"
}

extension AVSpeechSynthesisVoiceGender {
  func toInternal() -> VoiceGender {
    switch self {
    case .unspecified: return .unspecified
    case .male: return .male
    case .female: return .female
    }
  }
}

extension AVSpeechSynthesisVoiceQuality {
  func toInternal() -> VoiceQuality {
    switch self {
    case .default: return .default
    case .enhanced: return .enhanced
    case .premium: return .premium
    }
  }
}

public struct Voice: Hashable {
  public var language: String
  public var identifier: String
  public var name: String
  public var rate: Float? = nil  // Rate of speech, from 0.0 to 1.0, where 0.5 is the default rate.
  public var pitchMultiplier: Float? = nil // Pitch multiplier, from 0.5 to 2.0, where 1.0 is the default pitch.
  @available(macOS 10.15, *)
  public var gender: VoiceGender
  @available(macOS 10.14, *)
  public var quality: VoiceQuality
}

protocol BLSpeechSynthesizerDelegate: AnyObject {
  func synthesizerStarted()
  func synthesizerFinished()
  func synthesizing(range: NSRange)
}

protocol SpeechSynthesizerProtocol {
  func speak(_ text: String, isFinal: Bool, voice: Voice?)
  func pause()
  func resume()
  func stop()
}

class BLSpeechSynthesizer: NSObject, SpeechSynthesizerProtocol, @unchecked Sendable {
  private var synthesizer: AVSpeechSynthesizer? = nil
  weak var delegate: BLSpeechSynthesizerDelegate?
  private var buffer: BLStringBuffer!
  private var isFinished = false
  private var voice: AVSpeechSynthesisVoice!
  private var rate: Float?
  private var pitchMultiplier: Float?
  private var activateSSML: Bool = false
  
  var isSpeaking: Bool {
    return synthesizer?.isSpeaking ?? false
  }
  
  init(language: String, activateSSML: Bool = false) {
    self.voice = AVSpeechSynthesisVoice(language: language)
    self.buffer = Self.activateSSML(activateSSML)
    self.activateSSML = activateSSML
  }
  
  init(activateSSML: Bool = false) {
    self.buffer = Self.activateSSML(activateSSML)
    self.activateSSML = activateSSML
  }
  
  func speak(_ str: String, isFinal: Bool, voice: Voice? = nil) {
    setVoice(voice)
    isFinished = isFinal
    buffer.onMessageReceived(text: str)
    internalSpeak()
  }
  
  func pause() {
    synthesizer?.stopSpeaking(at: AVSpeechBoundary.word)
  }
  
  func resume() {
    internalSpeak()
  }
  
  func stop() {
    synthesizer?.stopSpeaking(at: AVSpeechBoundary.immediate)
    buffer.reset()
  }
  
  static func availableVoices() -> [Voice] {
    return AVSpeechSynthesisVoice.speechVoices().map { voice in
      Voice(language: voice.language,
            identifier: voice.identifier,
            name: voice.name,
            gender: voice.gender.toInternal(),
            quality: voice.quality.toInternal())
    }
  }
  
  private func internalSpeak() {
    self.synthesizer = self.synthesizer ?? initializeSynthesizer()
    buffer.flush(all: isFinished) { text in
//      print("[voice][SSML] \(text)")
//      let ssmlText = "<?xml version=\"1.0\"?>\(text)"
      let utterance = if #available(iOS 16.0, macOS 13.0, *), activateSSML == true {
        AVSpeechUtterance(ssmlRepresentation: text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? AVSpeechUtterance(string: text)
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
      DispatchQueue.global(qos: .background).async {
        self.synthesizer?.speak(utterance)
      }
    }
  }
  
  private func initializeSynthesizer() -> AVSpeechSynthesizer {
    let synth = AVSpeechSynthesizer()
    #if !os(macOS)
    synth.usesApplicationAudioSession = false
    #endif
    return synth
  }
  
  private func setVoice(_ voice: Voice?) {
    if let voice = voice {
      let voiceIdentifier = voice.identifier
      self.rate = voice.rate
      self.pitchMultiplier = voice.pitchMultiplier
      self.voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier)
    }
  }
  
  private static func activateSSML(_ activate: Bool) -> BLStringBuffer {
    if activate {
      return BLResponseSSMLStringBuffer(minLength: 10)
    } else {
      return BLResponseStringBuffer(minLength: 10)
    }
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

  @available(iOS 17.0, macOS 14.0, *)
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeak marker: AVSpeechSynthesisMarker, utterance: AVSpeechUtterance) {
    delegate?.synthesizing(range: marker.textRange)
  }
}
