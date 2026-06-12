import Foundation
@testable import bl_speech_recognizer

final class MockSpeechSynthesizer: SpeechSynthesizerProtocol {
  var spokenTexts: [String] = []
  var pausedCalled = false
  var resumedCalled = false
  var stoppedCalled = false
  var lastVoice: Voice?
  var lastIsFinal: Bool?

  func speak(_ text: String, isFinal: Bool, voice: Voice?) {
    spokenTexts.append(text)
    lastIsFinal = isFinal
    lastVoice = voice
  }

  func pause() {
    pausedCalled = true
  }

  func resume() {
    resumedCalled = true
  }

  func stop() {
    stoppedCalled = true
  }
}
