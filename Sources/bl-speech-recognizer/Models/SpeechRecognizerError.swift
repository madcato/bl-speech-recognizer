//
//  SpeechRecognizerError.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 1/1/25.
//

enum SpeechRecognizerError: Error {
  case auidoPropertiesError
  case notDetermined
  case userDenied
  case recognitionRestricted
  case speechRecognizerNotAvailable
  case recognitionTaskUnable
  case notAvailableInputs
  
  var message: String {
    switch self {
    case .auidoPropertiesError: return "audioSession properties weren't set because of an error."
    case .notDetermined: return "The app’s authorization status has not yet been determined."
    case .userDenied: return "The user denied your app’s request to perform speech recognition."
    case .recognitionRestricted: return "The device prevents your app from performing speech recognition."
    case .speechRecognizerNotAvailable : return "Speech Recognition not available"
    case .recognitionTaskUnable : return "Unable to create an SFSpeechAudioBufferRecognitionRequest object"
    case .notAvailableInputs: return "Not enough available inputs for microphone!"
    }
  }
}
