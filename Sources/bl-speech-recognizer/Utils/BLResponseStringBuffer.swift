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
    
    /// Shorter threshold for faster initial response - flush at clause boundaries
    private var clauseFlushLength: Int = 60
    
    /// Maximum buffer before forcing a flush (reduced for faster streaming)
    private var maxBufferLength: Int = 120
    
    /// Characters that indicate natural pause points (clause boundaries)
    private static let clauseDelimiters: CharacterSet = CharacterSet(charactersIn: ",.;:!?—–")
    
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
        
        // Strategy 1: Try to extract a complete sentence first (best quality)
        if let sentence = extractFirstSentence() {
            if sentence.count >= minLength {
                completionHandler(sentence)
                accumulatedText.removeFirst(sentence.count)
                return
            }
        }
        
        // Strategy 2: If buffer is getting long, flush at clause boundary for natural pauses
        // This prevents long waits while maintaining natural speech rhythm
        if accumulatedText.count >= clauseFlushLength {
            if let chunk = extractAtClauseBoundary() {
                if chunk.count >= minLength {
                    completionHandler(chunk)
                    accumulatedText.removeFirst(chunk.count)
                    return
                }
            }
        }
        
        // Strategy 3: Fallback - force flush at word boundary if buffer is too long
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
    
    /// Extracts text up to and including a clause delimiter (comma, semicolon, etc.)
    /// This allows flushing at natural pause points before a full sentence is complete.
    private func extractAtClauseBoundary() -> String? {
        // Look for clause delimiters followed by a space (to ensure it's a real boundary)
        let delimiters = [".", ",", ";", ":", "!", "?", "—", "–"]
        
        var bestIndex: String.Index? = nil
        
        for delimiter in delimiters {
            // Find delimiter followed by space (ensures we're at a real boundary)
            if let range = accumulatedText.range(of: delimiter + " ") {
                let candidateIndex = range.upperBound
                if bestIndex == nil || candidateIndex < bestIndex! {
                    bestIndex = candidateIndex
                }
            }
            // Also check for delimiter at end (waiting for more text)
            else if let range = accumulatedText.range(of: delimiter),
                    range.upperBound == accumulatedText.endIndex {
                // Don't flush if delimiter is at the very end - wait for more context
                continue
            }
        }
        
        if let index = bestIndex {
            return String(accumulatedText[..<index])
        }
        
        return nil
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
