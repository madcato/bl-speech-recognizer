//
//  ContinuousSpeechRecognizerTests.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 1/1/25.
//

import Speech
import XCTest
@testable import bl_speech_recognizer

// XCTest for ContinuousSpeechRecognizer
final class ContinuousSpeechRecognizerTests: XCTestCase {
  
  var speechRecognizer: ContinuousSpeechRecognizer!
  var englishAudioFileURL: URL! = nil
  var spanishAudioFileURL: URL! = nil
  
  override func setUp() {
    super.setUp()
    
    englishAudioFileURL = Bundle.module.url(forResource: "hello", withExtension: "m4a")!
    spanishAudioFileURL = Bundle.module.url(forResource: "hola", withExtension: "m4a")!
    speechRecognizer = ContinuousSpeechRecognizer()
  }
  
  override func tearDown() {
    speechRecognizer = nil
    super.tearDown()
  }
  
  @MainActor
  func testStartRecognition() {
    // Mock Audio Permissions
    let mockAuthorizationStatus: AVAudioSession.RecordPermission = .granted
    let audioSession = AVAudioSession.sharedInstance()
    audioSession.recordPermission = mockAuthorizationStatus
    
    let expectation = expectation(description: "Recognition started")
    
    speechRecognizer.start(inputType: .audioFile(englishAudioFileURL), locale: .init(identifier: "en_uS")) { result in
      switch result {
      case .success(let text):
        XCTAssertEqual(text, "Hello how are you")
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Recognition failed with error: \(error)")
      }
    }
    
    // Let some time to finish processing
    Thread.sleep(forTimeInterval: 5)
    
    speechRecognizer.stop()
    
    waitForExpectations(timeout: 10, handler: nil)
  }
  
  @MainActor
  func testStopRecognition() {
    speechRecognizer.start(inputType: .microphone, locale: .current) { _ in }
    
    
//    XCTAssertTrue(mockSpeechRecognizer.stoppedCalled, "Stop method was not called")
  }
}
