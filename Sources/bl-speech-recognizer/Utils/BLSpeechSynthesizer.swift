//
//  BLSpeechSynthesizer.swift
//  Marla
//
//  Created by Daniel Vela Angulo on 22/07/2019.
//  Copyright © 2019 veladan. All rights reserved.
//

import AVFoundation

protocol BLSpeechSynthesizerDelegate: AnyObject {
  func synthesizerStarted()
  func synthesizerFinished()
}

class BLSpeechSynthesizer: NSObject, @unchecked Sendable {
  private let synthesizer = AVSpeechSynthesizer()
  weak var delegate: BLSpeechSynthesizerDelegate?
  private var buffer = BLResponseStringBuffer(minLength: 10)
  private var isFinished = false
  private var language: String!

  var isSpeaking: Bool {
    return synthesizer.isSpeaking
  }

  init(language: String) {
    self.language = language
  }

  func stop() {
    synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
    buffer.reset()
  }

  func speak(_ str: String, isFinal: Bool) {
    isFinished = isFinal
    buffer.onMessageReceived(text: str)
    internalSpeak()
  }

  private func internalSpeak() {
    guard synthesizer.isSpeaking == false else { return }
    buffer.flush(all: isFinished) { text in
      let utterance = AVSpeechUtterance(string: text)
      utterance.voice = AVSpeechSynthesisVoice(language: language)
      synthesizer.delegate = self
      synthesizer.speak(utterance)
    }
  }

}

extension BLSpeechSynthesizer: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    delegate?.synthesizerStarted()
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    if buffer.accumulatedText.count > 0 {
      internalSpeak()
    } else {
      if isFinished {
        delegate?.synthesizerFinished()
      }
    }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    delegate?.synthesizerFinished()
  }
}
