//
//  CommandSpeechRecognizer.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Foundation

public class CommandSpeechRecognizer {
  private var speechRecognizer: BLSpeechRecognizer!
  private var completion: ((Result<String, Error>) -> Void)!
  
  @MainActor
  public func start(inputType: InputSourceType, locale: Locale = .current, completion: @escaping (Result<String, Error>) -> Void) {
    self.completion = completion
    let inputSource = InputSourceFactory.create(inputSource: inputType)
    do {
      speechRecognizer = try BLSpeechRecognizer(inputSource: inputSource, locale: locale, task:.query)
      speechRecognizer.delegate = self
      speechRecognizer.start()
    } catch {
      completion(.failure(error))
    }
  }
  
  public func stop() {
    speechRecognizer.delegate = nil
    speechRecognizer.stop()
  }
}

extension CommandSpeechRecognizer: BLSpeechRecognizerDelegate {
  
  func recognized(text: String, isFinal: Bool) {
    // TODO: Accumulate the result and call completion only when isFinal
    completion(.success(text))
  }
  
  func started() {
    // TODO: send to client
  }
  
  func finished() {
    // TODO: send to client
  }
  
  func speechRecognizer(available: Bool) {
    // TODO: send to client
  }
  
  func speechRecognizer(error: any Error) {
    // TODO: send to client
  }
}
