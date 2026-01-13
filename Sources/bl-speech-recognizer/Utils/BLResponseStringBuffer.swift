//
//  BLResponseStringBuffer.swift
//  butler-ios
//
//  Created by Daniel Vela on 9/5/24.
//

import Foundation

class BLResponseStringBuffer: BLStringBuffer {
    var accumulatedText: String = ""
    private var minLength: Int
    private var maxBufferLength: Int = 300  // Umbral para fallback si no hay oraciones (ajustable)
    
    init(minLength: Int = 0) {
        self.minLength = minLength
    }
    
    func onMessageReceived(text: String) {
        accumulatedText += text
    }
    
    func flush(all: Bool, completionHandler: (String) -> Void) {
        if all {
            let text = accumulatedText
            accumulatedText = ""
            if !text.isEmpty {
                completionHandler(text)
            }
            return
        }
        
        // Intenta extraer la primera oración completa usando NSLinguisticTagger
        if let sentence = extractFirstSentence() {
            if sentence.count >= minLength {
                completionHandler(sentence)
                // Remueve la oración del buffer
                accumulatedText.removeFirst(sentence.count)
                return
            }
        }
        
        // Fallback: Si el buffer es muy largo sin oración, flushea hasta el último espacio
        if accumulatedText.count > maxBufferLength {
            if let lastSpaceIndex = accumulatedText.lastIndex(of: " ") {
                let text = String(accumulatedText[...lastSpaceIndex])
                if text.count >= minLength {
                    completionHandler(text)
                    accumulatedText.removeFirst(text.count)
                }
            }
        }
    }
    
  private func extractFirstSentence() -> String? {
      let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
      tagger.string = accumulatedText
      
      var firstSentence: String?
      
      let fullRange = NSRange(location: 0, length: accumulatedText.utf16.count)
      
      tagger.enumerateTags(in: fullRange,
                           unit: .sentence,
                           scheme: .tokenType,
                           options: []) { tag, sentenceRange, stop in
          // sentenceRange es el rango de la oración completa (incluye puntuación)
          
          if let swiftRange = Range(sentenceRange, in: accumulatedText) {
              
              firstSentence = String(accumulatedText[swiftRange])
              
              // Detenemos la enumeración después de la primera oración encontrada
              stop.pointee = true
          }
          
          // Si no hay sentenceRange válido aún → seguimos (puede ser texto incompleto)
      }
      
      return firstSentence
  }
}
