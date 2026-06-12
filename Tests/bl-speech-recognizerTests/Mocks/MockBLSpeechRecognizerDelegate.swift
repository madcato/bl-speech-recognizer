import Foundation
@testable import bl_speech_recognizer

final class MockBLSpeechRecognizerDelegate: BLSpeechRecognizerDelegate {
  var recognizedText: String?
  var isFinal: Bool?
  var startedCalled = false
  var finishedCalled = false
  var availableCalled = false
  var availableValue: Bool?
  var errorCalled = false
  var receivedError: Error?

  func recognized(text: String, isFinal: Bool) {
    recognizedText = text
    self.isFinal = isFinal
  }

  func started() {
    startedCalled = true
  }

  func finished() {
    finishedCalled = true
  }

  func speechRecognizer(available: Bool) {
    availableCalled = true
    availableValue = available
  }

  func speechRecognizer(error: Error) {
    errorCalled = true
    receivedError = error
  }
}
