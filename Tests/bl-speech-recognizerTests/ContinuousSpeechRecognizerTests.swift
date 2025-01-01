//
//  ContinuousSpeechRecognizerTests.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 1/1/25.
//

import XCTest
@testable import bl_speech_recognizer

// Mock class for BLSpeechRecognizer
class MockBLSpeechRecognizer: BLSpeechRecognizer {
  var startedCalled = false
  var stoppedCalled = false
  
  override func start() {
    startedCalled = true
  }
  
  override func stop() {
    stoppedCalled = true
  }
}

// XCTest for ContinuousSpeechRecognizer
final class ContinuousSpeechRecognizerTests: XCTestCase {
  
  var speechRecognizer: ContinuousSpeechRecognizer!
  var mockSpeechRecognizer: MockBLSpeechRecognizer!
  
  override func setUp() {
    super.setUp()
    let inputsource = InputSourceFactory.create(inputSource: .microphone)
    mockSpeechRecognizer = try? MockBLSpeechRecognizer(inputSource: inputsource)
    speechRecognizer = ContinuousSpeechRecognizer()
    // Inject the mock or, if the original code doesn't support it, consider modifying
    // the original code to allow dependency injection for testing purposes.
  }
  
  override func tearDown() {
    speechRecognizer = nil
    mockSpeechRecognizer = nil
    super.tearDown()
  }
  
  @MainActor
  func testStartRecognition() {
    let expectation = expectation(description: "Recognition started")
    
    speechRecognizer.start(inputType: .microphone, locale: .current) { result in
      switch result {
      case .success(let text):
        XCTAssertEqual(text, "Expected Text")
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Recognition failed with error: \(error)")
      }
    }
    
    // Simulate the recognition result
    mockSpeechRecognizer.delegate?.recognized(text: "Expected Text", isFinal: true)
    
    waitForExpectations(timeout: 5, handler: nil)
    
    XCTAssertTrue(mockSpeechRecognizer.startedCalled, "Start method was not called")
  }
  
  @MainActor
  func testStopRecognition() {
    speechRecognizer.start(inputType: .microphone, locale: .current) { _ in }
    
    speechRecognizer.stop()
    
    XCTAssertTrue(mockSpeechRecognizer.stoppedCalled, "Stop method was not called")
  }
  
  // Additional tests can be added here for other methods like finished(), started(), etc.
}
