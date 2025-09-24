//
//  SpeechRecognizerError.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 1/1/25.
//

import Foundation

// Define custom errors for better clarity
enum SpeechRecognizerError: Error, LocalizedError {
  case speechRecognizerNotAvailable
  case userDenied
  case recognitionRestricted
  case notDetermined
  case recognitionTaskUnable
  case notAvailableInputs
  case audioInputFailure(String)
  case pauseFailed(String)
  case resumeFailed(String)
  
  var errorDescription: String? {
    switch self {
    case .speechRecognizerNotAvailable: return "Speech recognizer is not available for this locale."
    case .userDenied: return "User denied speech recognition permission."
    case .recognitionRestricted: return "Speech recognition is restricted on this device."
    case .notDetermined: return "Speech recognition authorization is not determined."
    case .recognitionTaskUnable: return "Unable to create recognition task."
    case .notAvailableInputs: return "No available audio inputs."
    case .audioInputFailure(let message): return "Audio input error: \(message)"
    case .pauseFailed(let message): return "Failed to pause recognition: \(message)"
    case .resumeFailed(let message): return "Failed to resume recognition: \(message)"
    }
  }
}
