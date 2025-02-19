//
//  CommandSpeechRecognizer.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Foundation

public enum CommandSpeechRecognizerEvent {
    case startedListening
    case stoppedListening
}

/// A speech recognizer that handles voice commands using a specific input source and locale
public class CommandSpeechRecognizer: @unchecked Sendable {
  
  /// The speech recognizer instance that processes the audio input.
  private var speechRecognizer: BLSpeechRecognizer!
  
  /// A closure that handles the result of the speech recognition, providing a success with the recognized text or a failure with an error.
  private var completion: ((Result<String, Error>) -> Void)!
  // Closure to be called upon an event appears
  private var eventLaunch: ((CommandSpeechRecognizerEvent) -> Void)?

  private var recognitionTimer: Timer? // Timer to track inactivity
  
  private var lastRecognizedText: String = ""
  
  public init() {}
  
  /// Starts the speech recognition process with a given input source type and locale.
  /// - Parameters:
  ///   - inputType: The type of input source to be used for speech recognition.
  ///   - locale: The locale to be used for speech recognition. Defaults to the current locale.
  ///   - completion: A closure that will be called with the result of the speech recognition task.
  @MainActor
  public func start(inputType: InputSourceType, locale: Locale = .current, completion: @escaping ((Result<String, Error>) -> Void), event: ((CommandSpeechRecognizerEvent) -> Void)? = nil) {
    self.completion = completion
    self.eventLaunch = event
    lastRecognizedText = ""
    // Create an input source based on the provided input type.
    let inputSource = InputSourceFactory.create(inputSource: inputType)
    
    do {
      // Attempt to initialize the speech recognizer with the specified input source and locale.
      speechRecognizer = try BLSpeechRecognizer(inputSource: inputSource, locale: locale, task: .query)
      // Set the delegate to self in order to handle speech recognition events.
      speechRecognizer.delegate = self
      // Start the speech recognition process.
      speechRecognizer.start()
    } catch {
      // Invoke the completion closure with the encountered error in case of failure.
      completion(.failure(error))
    }
  }
  
  /// Stops the ongoing speech recognition process.
  /// It also removes itself as a delegate from the speech recognizer.
  @MainActor
  public func stop() {
    // Stop the speech recognizer.
    speechRecognizer.stop()
    recognitionTimer?.invalidate() // Invalidate the timer when stopping
  }
}

extension CommandSpeechRecognizer: BLSpeechRecognizerDelegate {
  
  func recognized(text: String, isFinal: Bool) {
    // Append the newly recognized text
    if isFinal {
      self.completion(.success(lastRecognizedText))
    }
    lastRecognizedText = text
    // Reset and start the timer
    recognitionTimer?.invalidate()
    recognitionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
      guard let self = self else { return }
      DispatchQueue.main.async {
        self.stop()
      }
    }
  }
  
  
  func started() {
    eventLaunch?(.startedListening)
  }
  
  func finished() {
    eventLaunch?(.stoppedListening)
  }
  
  func speechRecognizer(available: Bool) {
    // TODO: send to client
  }
  
  func speechRecognizer(error: any Error) {
      completion?(.failure(error))
  }
}
