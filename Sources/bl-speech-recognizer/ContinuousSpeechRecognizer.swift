//
//  ContinuousSpeechRecognizer.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Foundation

public enum ContinuousSpeechRecognizerEvent {
    case startedListening
    case stoppedListening
}

/// The `ContinuousSpeechRecognizer` class is responsible for handling continuous speech recognition.
/// It can be used in long interactions with the user, like a chat or a dictation.
/// It manages the lifecycle of speech recognition using a `BLSpeechRecognizer` instance and informs the client of results and events.
public class ContinuousSpeechRecognizer {
  // The speech recognizer responsible for interpreting audio input.
  private var speechRecognizer: BLSpeechRecognizer!
  
  // Closure to be called upon completion with the recognition result or an error.
  private var completion: ((Result<String, Error>) -> Void)!
  // Closure to be called upon an event appears
  private var eventLaunch: ((ContinuousSpeechRecognizerEvent) -> Void)?
  
  public init() {}
  
  /// Starts the speech recognition process.
  ///
  /// - Parameters:
  ///   - inputType: The type of input source to be used for speech recognition. Possible values: 
  ///   - locale: The locale specifying language and regional settings, defaults to current locale.
  ///   - completion: A closure to be executed with the result of the recognition or an error.
  @MainActor
  public func start(inputType: InputSourceType, locale: Locale = .current, completion: @escaping ((Result<String, Error>) -> Void), event: ((ContinuousSpeechRecognizerEvent) -> Void)? = nil) {
    self.completion = completion
    self.eventLaunch = event
    let inputSource = InputSourceFactory.create(inputSource: inputType)
    do {
      // Initializes the speech recognizer with the given input source and locale.
      speechRecognizer = try BLSpeechRecognizer(inputSource: inputSource, locale: locale, task: .dictation)
      speechRecognizer.delegate = self
      // Starts the recognition process.
      speechRecognizer.start()
    } catch {
      // Calls completion with an error if initialization fails.
      completion(.failure(error))
    }
  }
  
  /// Stops the speech recognition process and cleans up resources.
  @MainActor
  public func stop() {
    // Stops the recognition process.
    speechRecognizer.stop()
  }
}

// MARK: - BLSpeechRecognizerDelegate

extension ContinuousSpeechRecognizer: BLSpeechRecognizerDelegate {
  func recognized(text: String, isFinal: Bool) {
    completion(.success(text))
  }
  
  func started() {
    eventLaunch?(.startedListening)
  }
  
  func finished() {
    eventLaunch?(.stoppedListening)
  }
  
  func speechRecognizer(available: Bool) {
    // TODO: Notify the client of availability change
  }
  
  func speechRecognizer(error: any Error) {
      completion?(.failure(error))
  }
}
