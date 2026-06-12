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

class BLSpeechSynthesizer: NSObject, SpeechSynthesizerProtocol {
  private lazy var synthesizer: AVSpeechSynthesizer = {
      let s = AVSpeechSynthesizer()
  #if !os(macOS)
      s.usesApplicationAudioSession = false
  #endif
      return s
  }()
  weak var delegate: BLSpeechSynthesizerDelegate?
  private var buffer: BLStringBuffer!
  private var isFinished = false
//  private var voice: AVSpeechSynthesisVoice!
  private var internalVoice: Voice?
  private var rate: Float?
  private var pitchMultiplier: Float?
  private var activateSSML: Bool = false
  
  /// Number of utterances currently queued in the synthesizer
  private var queuedUtteranceCount: Int = 0
  
  /// Minimum number of utterances to keep queued for seamless playback
  private let minQueuedUtterances: Int = 2
  
  var isSpeaking: Bool {
    return synthesizer.isSpeaking ?? false
  }
  
  init(language: String, activateSSML: Bool = false) {
//    self.voice = AVSpeechSynthesisVoice(language: language)
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
    // Queue multiple utterances for seamless playback
    enqueueAvailableUtterances()
  }
  
  func pause() {
    synthesizer.stopSpeaking(at: AVSpeechBoundary.word)
  }
  
  func resume() {
    enqueueAvailableUtterances()
  }
  
  func stop() {
    synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
    buffer.reset()
    queuedUtteranceCount = 0
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
  
  /// Enqueues all available utterances from the buffer.
  /// This method flushes multiple chunks to maintain a queue of utterances
  /// for seamless, gap-free playback.
  private func enqueueAvailableUtterances() {
    // Keep flushing until we have enough queued or buffer is exhausted
    var didEnqueue = true
    while didEnqueue {
      didEnqueue = false
      
      buffer.flush(all: isFinished) { text in
        guard text.isEmpty == false else { return }
        
        let utterance = if #available(iOS 16.0, macOS 13.0, *), activateSSML == true {
          AVSpeechUtterance(ssmlRepresentation: text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? AVSpeechUtterance(string: text)
        } else {
          AVSpeechUtterance(string: text)
        }
        
        if let rate = rate {
          utterance.rate = rate
        }
        if let pitchMultiplier = pitchMultiplier {
          utterance.pitchMultiplier = pitchMultiplier
        }
        
        DispatchQueue.main.async {
          if let internalVoice = self.internalVoice {
            let voiceIdentifier = internalVoice.identifier
            
            if let avVoice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
              self.rate = internalVoice.rate
              self.pitchMultiplier = internalVoice.pitchMultiplier
              utterance.voice = avVoice
            }
          }
          
          self.synthesizer.delegate = self
          self.synthesizer.speak(utterance)
          self.queuedUtteranceCount += 1
        }
        
        didEnqueue = true
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
    self.internalVoice = voice
//    if let voice = voice {
//      let voiceIdentifier = voice.identifier
//      Task { @MainActor in
//        // Aquí se carga la voz fuera del MainActor → sin unsafeForcedSync
//        if let avVoice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
//          self.rate = voice.rate
//          self.pitchMultiplier = voice.pitchMultiplier
//          self.voice = avVoice         // ← ahora ya es seguro
//        }
//      }
//    }
  }
  
  private static func activateSSML(_ activate: Bool) -> BLStringBuffer {
    return BLResponseStringBuffer(minLength: 10)
  }
}

extension BLSpeechSynthesizer: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    delegate?.synthesizerStarted()
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    queuedUtteranceCount = max(0, queuedUtteranceCount - 1)
    
    // Try to enqueue more utterances to maintain seamless playback
    enqueueAvailableUtterances()
    
    // Only signal finished when stream is complete AND no more queued utterances
    if isFinished && queuedUtteranceCount == 0 {
      delegate?.synthesizerFinished()
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
