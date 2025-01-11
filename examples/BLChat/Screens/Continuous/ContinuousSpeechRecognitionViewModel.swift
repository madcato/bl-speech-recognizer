//
//  ContinuousSpeechRecognitionViewModel.swift
//  BLChat
//
//  Created by Daniel Vela on 4/1/25.
//

import bl_speech_recognizer
import SwiftUI

// MARK: - ViewModel
class ContinuousSpeechRecognitionViewModel: ObservableObject {
  @Published var recognizedText: String = ""
  @Published var isRecording: Bool = false
  @Published var errorText: String = ""
  @Published var showError: Bool = false

  private var speechRecognizer = ContinuousSpeechRecognizer()
  
  @MainActor
  func startRecording() {
    isRecording = true
    
    speechRecognizer.start(inputType: .microphone, locale: .current) { result in
      switch result {
      case .success(let text):
        self.recognizedText = text
      case .failure(let error):
        self.showError(error.localizedDescription)
      }
    }
  }
  
  @MainActor
  func stopRecording() {
    isRecording = false
    speechRecognizer.stop()
  }
  
  func showError(_ errorText: String) {
    self.errorText = errorText
    showError = true
  }
}
