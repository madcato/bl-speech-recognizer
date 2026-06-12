import Foundation
@testable import bl_speech_recognizer

final class MockBLSpeechSynthesizerDelegate: BLSpeechSynthesizerDelegate {
  var startedCalled = false
  var finishedCalled = false
  var synthesizingRange: NSRange?

  func synthesizerStarted() {
    startedCalled = true
  }

  func synthesizerFinished() {
    finishedCalled = true
  }

  func synthesizing(range: NSRange) {
    synthesizingRange = range
  }
}
