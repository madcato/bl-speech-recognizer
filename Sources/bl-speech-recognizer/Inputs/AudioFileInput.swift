//
//  AudioFileInput.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 1/1/25.
//

import Speech

class AudioFileInput: InputSource {
  private let fileURL: URL
  
  init(url: URL) {
    self.fileURL = url
  }

  func initialize() throws -> SFSpeechRecognitionRequest? {
    return SFSpeechURLRecognitionRequest(url: fileURL)
  }

  func stop() {
  }
  
  
}
