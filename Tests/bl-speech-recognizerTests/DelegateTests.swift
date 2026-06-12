import Foundation
import Testing
@testable import bl_speech_recognizer

@Suite("Delegate Tests")
struct DelegateTests {

  @Test("MockBLSpeechRecognizerDelegate captures recognized text")
  func testMockSpeechRecognizerDelegate() {
    let mock = MockBLSpeechRecognizerDelegate()
    mock.recognized(text: "Hello", isFinal: false)

    #expect(mock.recognizedText == "Hello")
    #expect(mock.isFinal == false)
  }

  @Test("MockBLSpeechRecognizerDelegate tracks started and finished")
  func testMockDelegateLifecycle() {
    let mock = MockBLSpeechRecognizerDelegate()
    
    #expect(mock.startedCalled == false)
    #expect(mock.finishedCalled == false)
    
    mock.started()
    #expect(mock.startedCalled == true)
    
    mock.finished()
    #expect(mock.finishedCalled == true)
  }

  @Test("MockBLSpeechRecognizerDelegate captures errors")
  func testMockDelegateError() {
    let mock = MockBLSpeechRecognizerDelegate()
    let error = SpeechRecognizerError.userDenied
    
    mock.speechRecognizer(error: error)
    
    #expect(mock.errorCalled == true)
    #expect(mock.receivedError is SpeechRecognizerError)
  }

  @Test("MockBLSpeechRecognizerDelegate captures availability")
  func testMockDelegateAvailability() {
    let mock = MockBLSpeechRecognizerDelegate()
    
    mock.speechRecognizer(available: true)
    
    #expect(mock.availableCalled == true)
    #expect(mock.availableValue == true)
  }

  @Test("MockBLSpeechSynthesizerDelegate tracks synthesis events")
  func testMockSynthesizerDelegate() {
    let mock = MockBLSpeechSynthesizerDelegate()
    
    #expect(mock.startedCalled == false)
    #expect(mock.finishedCalled == false)
    
    mock.synthesizerStarted()
    #expect(mock.startedCalled == true)
    
    mock.synthesizerFinished()
    #expect(mock.finishedCalled == true)
  }

  @Test("MockBLSpeechSynthesizerDelegate captures range")
  func testMockSynthesizerRange() {
    let mock = MockBLSpeechSynthesizerDelegate()
    let range = NSRange(location: 0, length: 5)
    
    mock.synthesizing(range: range)
    
    #expect(mock.synthesizingRange?.location == 0)
    #expect(mock.synthesizingRange?.length == 5)
  }

  @Test("MockSpeechSynthesizer captures spoken text")
  func testMockSpeechSynthesizer() {
    let mock = MockSpeechSynthesizer()
    
    mock.speak("Hello", isFinal: false, voice: nil)
    mock.speak("world", isFinal: true, voice: nil)
    
    #expect(mock.spokenTexts.count == 2)
    #expect(mock.spokenTexts[0] == "Hello")
    #expect(mock.spokenTexts[1] == "world")
    #expect(mock.lastIsFinal == true)
  }

  @Test("MockSpeechSynthesizer tracks control methods")
  func testMockSpeechSynthesizerControls() {
    let mock = MockSpeechSynthesizer()
    
    #expect(mock.pausedCalled == false)
    #expect(mock.resumedCalled == false)
    #expect(mock.stoppedCalled == false)
    
    mock.pause()
    #expect(mock.pausedCalled == true)
    
    mock.resume()
    #expect(mock.resumedCalled == true)
    
    mock.stop()
    #expect(mock.stoppedCalled == true)
  }

  @Test("MockSpeechSynthesizer captures voice")
  func testMockSpeechSynthesizerVoice() {
    let mock = MockSpeechSynthesizer()
    let voice = Voice(language: "en-US", identifier: "id", name: "Test", gender: .female, quality: .enhanced)
    
    mock.speak("Hello", isFinal: true, voice: voice)
    
    #expect(mock.lastVoice?.name == "Test")
    #expect(mock.lastVoice?.language == "en-US")
  }
}
