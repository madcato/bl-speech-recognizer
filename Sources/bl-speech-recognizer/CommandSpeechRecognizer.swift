//
//  CommandSpeechRecognizer.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Foundation

/// A speech recognizer that handles voice commands using a specific input source and locale
public class CommandSpeechRecognizer: @unchecked Sendable {
  
  /// The speech recognizer instance that processes the audio input.
  private var speechRecognizer: BLSpeechRecognizer!
  
  /// A closure that handles the result of the speech recognition, providing a success with the recognized text or a failure with an error.
  private var completion: ((Result<String, Error>) -> Void)!

  private var recognitionTimer: Timer? // Timer to track inactivity
  
  /// Starts the speech recognition process with a given input source type and locale.
  /// - Parameters:
  ///   - inputType: The type of input source to be used for speech recognition.
  ///   - locale: The locale to be used for speech recognition. Defaults to the current locale.
  ///   - completion: A closure that will be called with the result of the speech recognition task.
  @MainActor
  public func start(inputType: InputSourceType, locale: Locale = .current, completion: @escaping (Result<String, Error>) -> Void) {
    self.completion = completion
    
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
      self.completion(.success(text))
    }
    
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
