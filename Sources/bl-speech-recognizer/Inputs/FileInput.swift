//
//  FileInput.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 1/1/25.
//

import Speech

class FileInput: InputSource {
  private let fileURL: URL
  
  init(url: URL) {
    self.fileURL = url
  }

  func initialize() {
  }
  
  func configure(with recognitionRequest: SFSpeechAudioBufferRecognitionRequest?) {
  }
  
  func stop() {
  }
  
  
}
