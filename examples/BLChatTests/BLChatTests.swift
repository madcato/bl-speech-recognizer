//
//  BLChatTests.swift
//  BLChatTests
//
//  Created by Daniel Vela on 11/1/25.
//

import Speech
@testable import BLChat
@testable import bl_speech_recognizer
import Foundation
import XCTest

final class ContinuousSpeechRecognizerTests: XCTestCase {
  
  var continuousSpeechRecognizer: ContinuousSpeechRecognizer!
  var commandSpeechRecognizer: CommandSpeechRecognizer!
  var testEnglishAudioFileURL: URL! = nil
  var testSpanishAudioFileURL: URL! = nil
  
  override func setUp() {
    super.setUp()
    
    // Load the test audio file from the test bundle
    testEnglishAudioFileURL = Bundle.main.url(forResource: "hello", withExtension: "m4a")!
    testSpanishAudioFileURL = Bundle.main.url(forResource: "hola", withExtension: "m4a")!
    continuousSpeechRecognizer = ContinuousSpeechRecognizer()
    commandSpeechRecognizer = CommandSpeechRecognizer()
  }
  
  override func tearDown() {
    continuousSpeechRecognizer = nil
    commandSpeechRecognizer = nil
    super.tearDown()
  }
  
  @MainActor
  func testStartContinuousRecognitionWithAudioFileInput() {
    let expectation = self.expectation(description: "Recognition with audio file input started")
    
    continuousSpeechRecognizer.start(inputType: .audioFile(testEnglishAudioFileURL), locale: .init(identifier: "en_US")) { result in
      switch result {
      case .success(let text):
        XCTAssertEqual(text, "Hello")  // Only returns the first recognition, because it returns the recognized text while continue recognizing
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Recognition failed with error: \(error)")
      }
    }
    
    Thread.sleep(forTimeInterval: 3)
    continuousSpeechRecognizer.stop()
    
    waitForExpectations(timeout: 5, handler: nil)
  }
   
  @MainActor
  func testStartCommandRecognitionWithAudioFileInput() {
    let expectation = self.expectation(description: "Recognition with audio file input started")
    
    commandSpeechRecognizer.start(inputType: .audioFile(testEnglishAudioFileURL), locale: .init(identifier: "en_US")) { result in
      switch result {
      case .success(let text):
        XCTAssertEqual(text, "Hello how are you")
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Recognition failed with error: \(error)")
      }
    }
    
    // In command recognition mode, speech recognition stops itself
    
    waitForExpectations(timeout: 5, handler: nil)
  }
  
  @MainActor
  func testStartContinuousRecognitionWithAudioFileInputSpanish() {
    let expectation = self.expectation(description: "Recognition with audio file input started")
    
    continuousSpeechRecognizer.start(inputType: .audioFile(testSpanishAudioFileURL), locale: .init(identifier: "es_ES")) { result in
      switch result {
      case .success(let text):
        XCTAssertEqual(text, "Hola")  // Only returns the first recognition, because it returns the recognized text while continue recognizing
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Recognition failed with error: \(error)")
      }
    }
    
    Thread.sleep(forTimeInterval: 3)
    continuousSpeechRecognizer.stop()
    
    waitForExpectations(timeout: 10, handler: nil)
  }
  
  @MainActor
  func testStartCommandRecognitionWithAudioFileInputSpanish() {
    let expectation = self.expectation(description: "Recognition with audio file input started")
    
    commandSpeechRecognizer.start(inputType: .audioFile(testSpanishAudioFileURL), locale: .init(identifier: "es_ES")) { result in
      switch result {
      case .success(let text):
        XCTAssertEqual(text, "Hola cómo estás")
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Recognition failed with error: \(error)")
      }
    }
    
    // In command recognition mode, speech recognition stops itself
    
    waitForExpectations(timeout: 10, handler: nil)
  }
}
