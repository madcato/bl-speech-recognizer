//
//  InterruptibleChat.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Foundation

/// The `InterruptibleChat` class is responsible for handling continuous speech recognition.
/// Also can synthesize text to speech. If user speaks while synthesizing, it becomes stopped.
/// The text to be synthesize can be added as a stream. This class store the text to be synthesized.
/// It can be used in long interactions with the user, like a chat.
/// It manages the lifecycle of speech recognition using a `BLSpeechRecognizer` instance and informs the client of results and events.
public class InterruptibleChat: @unchecked Sendable {
  // The speech recognizer responsible for interpreting audio input.
  private var speechRecognizer: BLSpeechRecognizer!
  // The speech synthesizer responsible for interpreting audio output.
  private var speechSynthesizer: BLSpeechSynthesizer!
  
  // Closure to be called upon completion with the recognition result or an error.
  private var completion: ((Result<InterruptibleChat.Completion, Error>) -> Void)!
  
  private var recognitionTimer: Timer? // Timer to track inactivity
  
  public init() {}
  
  public struct Completion {
    public let text: String
    public let isFinal: Bool
  }
  
  /// Starts the speech recognition process.
  ///
  /// - Parameters:
  ///   - inputType: The type of input source to be used for speech recognition. Possible values:
  ///   - locale: The locale specifying language and regional settings, defaults to current locale.
  ///   - completion: A closure to be executed with the result of the recognition or an error.
  @MainActor
  public func start(inputType: InputSourceType, locale: Locale = .current, completion: @escaping (Result<InterruptibleChat.Completion, Error>) -> Void) {
    self.completion = completion
    let inputSource = InputSourceFactory.create(inputSource: inputType)
    do {
      // Initializes the speech recognizer with the given input source and locale.
      speechRecognizer = try BLSpeechRecognizer(inputSource: inputSource, locale: locale, task: .query)
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
    // Stop the speech recognizer.
    speechRecognizer.stop()
    recognitionTimer?.invalidate() // Invalidate the timer when stopping
  }
  
  /// Starts or continues the speech synthesizing process and cleans up resources.
  @MainActor
  public func synthesize(text: String, isFinal: Bool, locale: Locale) {
    if speechSynthesizer == nil {
      speechSynthesizer = BLSpeechSynthesizer(language: locale.identifier)
    }
    speechSynthesizer.delegate = self
    speechSynthesizer.speak(text, isFinal: isFinal)
  }
  
  /// Stops the speech synthesizing process and cleans up resources.
  @MainActor
  public func stopSynthesizing() {
    speechSynthesizer?.stop()
  }
}

// MARK: - BLSpeechRecognizerDelegate

extension InterruptibleChat: @preconcurrency BLSpeechRecognizerDelegate {
  @MainActor func recognized(text: String, isFinal: Bool) {
    self.stopSynthesizing()
    
    // Append the newly recognized text
    self.completion(.success(.init(text: text, isFinal: isFinal)))
    // Reset and start the timer
    recognitionTimer?.invalidate()
    recognitionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
      guard let self = self else { return }
      DispatchQueue.main.async {
        self.stop()
        self.speechRecognizer.start()
      }
    }
  }
  
  func started() {
    // TODO: Notify the client that recognition has started
  }
  
  func finished() {
    // TODO: Notify the client that recognition has finished
  }
  
  func speechRecognizer(available: Bool) {
    // TODO: Notify the client of availability change
  }
  
  func speechRecognizer(error: any Error) {
    // TODO: Notify the client of the error
  }
}

extension InterruptibleChat: BLSpeechSynthesizerDelegate {
  func synthesizerStarted() {
    // TODO: Notify the client that synthesizing has finished
  }
  
  func synthesizerFinished() {
    // TODO: Notify the client that synthesizing has finished
  }
  
  
}

