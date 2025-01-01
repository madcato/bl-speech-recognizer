//
//  InputSource.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Speech

// Enum representing different input source types for speech recognition
public enum InputSourceType {
  case microphone
  case audioFile(URL)
  case customStream
}

// Protocol defining the operations for an input source
protocol InputSource {
  /// Initializes the input source, preparing it for usage.
  func initialize()
  
  /**
   Configures the input source with a given speech audio buffer recognition request.
   
   - Parameter recognitionRequest: An optional SFSpeechAudioBufferRecognitionRequest to configure the input source with.
   
   - Throws: An error if configuration fails.
   */
  func configure(with recognitionRequest: SFSpeechAudioBufferRecognitionRequest?) throws
  
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
  static func create(inputSource type: InputSourceType) -> InputSource {
    switch type {
    case .microphone:
      return MicrophoneInputSource()  // Returns an instance of a microphone input source
    case .audioFile(let url):
      return FileInput(url: url)      // Returns an instance for audio file input with the specified URL
    case .customStream:
      return CustomInputSource()      // Returns an instance of a custom input stream
    }
  }
}
