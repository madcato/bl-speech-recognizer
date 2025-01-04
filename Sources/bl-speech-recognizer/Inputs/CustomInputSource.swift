//
//  CustomInputSource.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Speech

class CustomInputSource: InputSource {
  func initialize() throws -> SFSpeechRecognitionRequest? {
//    public func processAudio(_ audioBuffer: AVAudioPCMBuffer) {
//      recognitionRequest?.append(audioBuffer)
//    }
//    
    return nil
  }
  
  func configure(with recognitionRequest: SFSpeechRecognitionRequest?) throws {
  }

  func stop() {
  }
}
