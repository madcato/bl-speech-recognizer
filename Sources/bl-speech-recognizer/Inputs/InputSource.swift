//
//  InputSource.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Speech

public enum InputSourceType {
  case microphone
  case audioFile(URL)
  case customStream
}

protocol InputSource {
  func initialize()
  func configure(with recognitionRequest: SFSpeechAudioBufferRecognitionRequest?)
  func stop()
}

class InputSourceFactory {
  static func create(inputSource type: InputSourceType) -> InputSource {
    switch type {
    case .microphone:
      return MicrophoneInputSource()
    case .audioFile(let url):
      return FileInput(url: url)
    case .customStream:
      return CustomInputSource()
    }
  }
}
