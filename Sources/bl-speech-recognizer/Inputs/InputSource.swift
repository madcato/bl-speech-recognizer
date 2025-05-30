//
//  InputSource.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Speech

/**
 Represents the type of input source for speech recognition.

 - Cases:
   - microphone: Indicates that the input source is a live audio stream from a microphone.
   - audioFile(URL): Represents an input source that is an audio file located at a specified URL.
   - customStream: Indicates a custom input stream, which may be used for more advanced or specialized input scenarios.
 */
public enum InputSourceType {
  case microphone
  case audioFile(URL)
  case customStream
}
// Protocol defining the operations for an input source
protocol InputSource {
  /// Initializes the input source, preparing it for usage.
  /// Must return a SFSpeechRecognitionRequest object.
  func initialize() throws -> SFSpeechRecognitionRequest?
  
  /// Stops the input source, ceasing its operation.
  func stop()
}

// Factory class to create instances of input sources based on the specified type
class InputSourceFactory {
  
  /**
   Creates and returns an appropriate InputSource instance corresponding to the given InputSourceType.
   
   - Parameter type: The type of input source to create.
   
   - Returns: An InputSource instance corresponding to the specified type.
   */
  static func create(inputSource type: InputSourceType, speakDetectedCallback: (() -> Void)? = nil, silenceDetectedCallback: (() -> Void)? = nil) -> InputSource {
    switch type {
    case .microphone:
      return MicrophoneInputSource(speakDetected: speakDetectedCallback, silenceDetected: silenceDetectedCallback)  // Returns an instance of a microphone input source
    case .audioFile(let url):
      return AudioFileInput(url: url)      // Returns an instance for audio file input with the specified URL
    case .customStream:
      return CustomInputSource()      // Returns an instance of a custom input stream
    }
  }
}
