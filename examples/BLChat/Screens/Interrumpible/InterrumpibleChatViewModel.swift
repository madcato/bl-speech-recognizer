//
//  InterrumpibleChatViewModel.swift
//  BLChat
//
//  Created by Daniel Vela on 4/1/25.
//

import bl_speech_recognizer
import SwiftUI

// MARK: - ViewModel
class InterrumpibleChatViewModel: ObservableObject {
  @Published var recognizedText: String = ""
  @Published var isRecording: Bool = false
  @Published var errorText: String = ""
  @Published var showError: Bool = false

  private var interrumpibleChat = InterrumpibleChat()
  
  @MainActor
  func startRecording() {
    isRecording = true
    
    interrumpibleChat.synthesize(text: textToSynthesize, isFinal: true, locale: .current)
    
    interrumpibleChat.start(inputType: .microphone, locale: .current) { result in
      switch result {
      case .success(let completion):
        self.recognizedText = completion.text
      case .failure(let error):
        self.showError(error.localizedDescription)
      }
    }
  }
  
  @MainActor
  func stopRecording() {
    isRecording = false
    interrumpibleChat.stop()
    interrumpibleChat.stopSynthesizing()
  }
  
  func showError(_ errorText: String) {
    self.errorText = errorText
    showError = true
  }
  
  private let textToSynthesize: String = """
  "Bitcoin is a form of digital currency, also known as a cryptocurrency. It was invented in 2008 by an anonymous person or group of people using the pseudonym Satoshi Nakamoto. The currency began use in 2009 when its implementation was released as open-source software.
  
  Bitcoin operates on a decentralized network using technology known as blockchain, which is a distributed ledger that records all transactions across a network of computers. This structure ensures transparency and prevents double-spending and tampering.

  Key features of Bitcoin include:

  1. **Decentralization**: Unlike traditional currencies, Bitcoin is not controlled by any central authority, such as a government or financial institution.

  2. **Limited Supply**: Bitcoin has a capped supply of 21 million coins, making it a deflationary currency. New bitcoins are created through a process called mining, where powerful computers solve complex mathematical problems.

  3. **Anonymity and Transparency**: While all Bitcoin transactions are recorded on the blockchain and are publicly visible, the identities of the individuals involved in the transactions are encrypted.

  4. **Divisibility**: Bitcoin can be divided into smaller units called satoshis. One bitcoin is equivalent to 100 million satoshis, making it highly divisible and practical for smaller transactions.

  5. **Global Reach**: Bitcoin can be sent and received anywhere in the world, and it's not bound by exchange rates or cross-border fees typical of traditional currencies.

  Bitcoin has sparked significant interest and debate regarding its role as a store of value, investment vehicle, and alternative to traditional payment systems. Its price is highly volatile, and it has both staunch advocates and critics. Advocates see it as an innovation in financial systems, potentially offering more freedom and accessibility, while critics point to concerns like its environmental impact from energy-intensive mining processes and its use in illegal activities due to its anonymity.
"""
}
