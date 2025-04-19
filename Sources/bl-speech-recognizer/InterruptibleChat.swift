//
//  InterruptibleChat.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Foundation

public enum InterrumpibleChatEvent {
  case startedListening
  case stoppedListening
  case startedSpeaking
  case stoppedSpeaking
  case detectedSpeaking
}

/// The `InterruptibleChat` class is responsible for handling continuous speech recognition.
/// Also can synthesize text to speech. If user speaks while synthesizing, it becomes stopped.
/// The text to be synthesize can be added as a stream. This class store the text to be synthesized.
/// It can be used in long interactions with the user, like a chat.
/// It manages the lifecycle of speech recognition using a `BLSpeechRecognizer` instance and informs the client of results and events.
public class InterruptibleChat: @unchecked Sendable {
  // The speech recognizer responsible for interpreting audio input.
  private var speechRecognizer: BLSpeechRecognizer?
  // The speech synthesizer responsible for interpreting audio output.
  private var speechSynthesizer: BLSpeechSynthesizer!
  
  // Closure to be called upon completion with the recognition result or an error.
  private var completion: ((Result<InterruptibleChat.Completion, Error>) -> Void)!
  // Closure to be called upon an event appears
  private var eventLaunch: ((InterrumpibleChatEvent) -> Void)?
  
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
  public func start(inputType: InputSourceType, locale: Locale = .current, completion: @escaping ((Result<InterruptibleChat.Completion, Error>) -> Void), event: ((InterrumpibleChatEvent) -> Void)? = nil) {
    self.completion = completion
    self.eventLaunch = event
    let inputSource = InputSourceFactory.create(inputSource: inputType, speakDetectedCallback: userIsSpeaking)
    do {
      // Initializes the speech recognizer with the given input source and locale.
      speechRecognizer = try BLSpeechRecognizer(inputSource: inputSource, locale: locale, shouldReportPartialResults: false, task: .query)
      speechRecognizer?.delegate = self
      // Starts the recognition process.
      speechRecognizer?.start()
    } catch {
      // Calls completion with an error if initialization fails.
      completion(.failure(error))
    }
  }
  
  /// Stops the speech recognition process and cleans up resources.
  @MainActor
  public func stop() {
    // Stop the speech recognizer.
    speechRecognizer?.stop()
  }
  
  /// Starts or continues the speech synthesizing process and cleans up resources.
  @MainActor
  public func synthesize(text: String, isFinal: Bool, locale: Locale) {
    if speechSynthesizer == nil {
      speechSynthesizer = BLSpeechSynthesizer(language: locale.identifier)
      speechSynthesizer.delegate = self
    }
    speechSynthesizer.speak(text, isFinal: isFinal)
  }
  
  @MainActor
  public func synthesize(text: String, isFinal: Bool, voice: Voice) {
    if speechSynthesizer == nil {
      speechSynthesizer = BLSpeechSynthesizer(voice: voice)
      speechSynthesizer.delegate = self
    }
    speechSynthesizer.speak(text, isFinal: isFinal)
  }
  
  /// Stops the speech synthesizing process and cleans up resources.
  @MainActor
  public func stopSynthesizing() {
    speechSynthesizer?.stop()
  }
  
  /// List all available voices
  public func listVoices() -> [Voice] {
    return BLSpeechSynthesizer.availableVoices()
  }
  
  // Reset synthesizer object. This allows to change voice
  public func resetSynthesizer() {
    speechSynthesizer = nil
  }
  
  private func userIsSpeaking() {
    eventLaunch?(.detectedSpeaking)
  }
}

// MARK: - BLSpeechRecognizerDelegate

extension InterruptibleChat: @preconcurrency BLSpeechRecognizerDelegate {
  @MainActor func recognized(text: String, isFinal: Bool) {
    self.stopSynthesizing()
    
    // Append the newly recognized text
    self.completion(.success(.init(text: text, isFinal: true)))
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

extension InterruptibleChat: BLSpeechSynthesizerDelegate {
  func synthesizerStarted() {
    eventLaunch?(.startedSpeaking)
  }
  
  func synthesizerFinished() {
    eventLaunch?(.stoppedSpeaking)
  }
  
  
}

