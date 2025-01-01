//
//  SpeechRecognitionResult.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 1/1/25.
//

struct SpeechRecognitionResult {
  let transcription: String
  let confidence: Double
  let timestamp: Double
  let wordConfidence: [String: Double]
  let wordTimestamps: [String: Double]
  let wordTranscriptions: [String: String]
  let words: [String]
  let utteranceId: String
  let isInterrupted: Bool
  let isPaused: Bool
  let isStopped: Bool
  let isTranscribing: Bool
  let isTranscribingFinished: Bool
  let isTranscribingStarted: Bool
  let isTranscribingStopped: Bool
  let isFinal: Bool
}
