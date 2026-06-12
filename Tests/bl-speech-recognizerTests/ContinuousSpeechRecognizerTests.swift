//
//  ContinuousSpeechRecognizerTests.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 1/1/25.
//

import XCTest
@testable import bl_speech_recognizer

// XCTest for ContinuousSpeechRecognizer
final class ContinuousSpeechRecognizerTests: XCTestCase {

  var speechRecognizer: ContinuousSpeechRecognizer!

  override func setUp() {
    super.setUp()
    speechRecognizer = ContinuousSpeechRecognizer()
  }

  override func tearDown() {
    speechRecognizer = nil
    super.tearDown()
  }

  func testInit() {
    XCTAssertNotNil(speechRecognizer)
  }

  // TODO: Replace with mock-based tests after Phase 4 (protocol extraction)
  // @MainActor
  // func testStartRecognition() { ... }
  // @MainActor
  // func testStopRecognition() { ... }
}
