//
//  CommandSpeechRecognitionViewModel.swift
//  BLChat
//
//  Created by Daniel Vela on 4/1/25.
//

import bl_speech_recognizer
import SwiftUI

// MARK: - ViewModel
class CommandSpeechRecognitionViewModel: ObservableObject {
  @Published var isRecording: Bool = false
  @Published var errorText: String = ""
  @Published var showError: Bool = false
  @Published var selectedOption: String = ""
  let options = ["Run", "Stop", "Delete files", "Tell me the status", "Not recognized"]

  private var speechRecognizer = CommandSpeechRecognizer()
  
  @MainActor
  func startRecording() {
    isRecording = true
    selectedOption = ""
    speechRecognizer.start(inputType: .microphone, locale: .current) { result in
      switch result {
      case .success(let text):
        if let _ = self.options.first(where: { $0 == text }) {
          self.selectedOption = text
        } else {
          self.selectedOption = "Not recognized"
        }
        self.isRecording = false
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
  
  func selectOption(_ option: String) {
    selectedOption = option
  }
  
  func deselectOption() {
    selectedOption = ""
  }
}
