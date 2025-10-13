//
//  InterruptibleChatViewModel.swift
//  BLChat
//
//  Created by Daniel Vela on 4/1/25.
//

import bl_speech_recognizer
import SwiftUI

// MARK: - ViewModel
class InterruptibleChatViewModel: ObservableObject {
  @Published var recognizedText: String = ""
  @Published var isRecording: Bool = false
  @Published var errorText: String = ""
  @Published var showError: Bool = false
  @Published var selectedVoice: Voice?
  @Published var availableVoices: [Voice] = []
  @Published var listening: Bool = false
  @Published var speaking: Bool = false

  private var interruptibleChat: InterruptibleChat
  
  init() {
    do {
      self.interruptibleChat = try InterruptibleChat(inputType: .microphone, activateSSML: false)
    } catch {
      fatalError("Error creating InterruptibleChat: \(error)")
    }
    self.availableVoices = InterruptibleChat.listVoices().filter({ voice in
      voice.language == "es-ES" || voice.language == "en-US"
    })
    self.selectedVoice = availableVoices.first
  }
  
  @MainActor
  func startRecording() {
    isRecording = true
    
    synthesize()
    
    interruptibleChat.start(completion: { result in
      switch result {
      case .success(let completion):
        self.recognizedText = completion.text
        if completion.isFinal {
          self.synthesize()
        }
      case .failure(let error):
        self.showError(error.localizedDescription)
      }
    }) { event in
      Task {
        switch event {
        case .startedListening:
          self.listening = true
        case .startedSpeaking:
          self.speaking = true
        case .stoppedListening:
          self.listening = false
        case .stoppedSpeaking:
          self.speaking = false
        case .detectedSpeaking:
          self.listening = true
        case .synthesizingRange(_):
          break
        }
      }
    }
  }
  
  @MainActor
  func stopRecording() {
    isRecording = false
    interruptibleChat.stop()
    interruptibleChat.stopSynthesizing()
  }
  
  @MainActor
  func selectVoice(_ voice: Voice) {
    stopRecording()
    selectedVoice = voice 
  }
  
  func showError(_ errorText: String) {
    DispatchQueue.main.async {
      self.errorText = errorText
      self.showError = true
    }
  }

  private func synthesize() {
    Task {
      let text = switch(selectedVoice?.language) {
      case "en-US":
        textToSynthesize_en
      case "es-ES":
        textToSynthesize_es
      default:
        textToSynthesize_en
      }
      await self.interruptibleChat.synthesize(text: text, isFinal: true, voice: selectedVoice!)
    }
  }
  
  private let textToSynthesize_en: String = """
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
  private let textToSynthesize_es: String = """
  "Bitcoin es una forma de moneda digital, también conocida como criptomoneda. Fue inventada en 2008 por una persona anónima o un grupo de personas que usaban el seudónimo de Satoshi Nakamoto. La moneda comenzó a usarse en 2009 cuando su implementación se lanzó como software de código abierto.

Bitcoin opera en una red descentralizada que utiliza tecnología conocida como blockchain, que es un libro de contabilidad distribuido que registra todas las transacciones en una red de computadoras. Esta estructura garantiza la transparencia y evita el doble gasto y la manipulación.

Las características clave de Bitcoin incluyen:

1. **Descentralización**: a diferencia de las monedas tradicionales, Bitcoin no está controlado por ninguna autoridad central, como un gobierno o una institución financiera.

2. **Oferta limitada**: Bitcoin tiene una oferta limitada de 21 millones de monedas, lo que lo convierte en una moneda deflacionaria. Los nuevos bitcoins se crean a través de un proceso llamado minería, donde computadoras poderosas resuelven problemas matemáticos complejos.

3. **Anonimato y transparencia**: si bien todas las transacciones de Bitcoin se registran en la cadena de bloques y son visibles públicamente, las identidades de las personas involucradas en las transacciones están encriptadas.

4. **Divisibilidad**: Bitcoin se puede dividir en unidades más pequeñas llamadas satoshis. Un bitcoin equivale a 100 millones de satoshis, lo que lo hace altamente divisible y práctico para transacciones más pequeñas.

5. **Alcance global**: Bitcoin se puede enviar y recibir en cualquier parte del mundo y no está sujeto a tipos de cambio ni a tarifas transfronterizas típicas de las monedas tradicionales.

Bitcoin ha generado un interés y un debate significativos con respecto a su papel como reserva de valor, vehículo de inversión y alternativa a los sistemas de pago tradicionales. Su precio es muy volátil y tiene defensores y críticos acérrimos. Los defensores lo ven como una innovación en los sistemas financieros, que potencialmente ofrece más libertad y accesibilidad, mientras que los críticos señalan preocupaciones como su impacto ambiental debido a los procesos de minería de alto consumo de energía y su uso en actividades ilegales debido a su anonimato.
"""
}
