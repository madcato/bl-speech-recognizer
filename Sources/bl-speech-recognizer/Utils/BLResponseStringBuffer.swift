//
//  BLResponseStringBuffer.swift
//  butler-ios
//
//  Created by Daniel Vela on 9/5/24.
//

import Foundation

class BLResponseStringBuffer {
  var accumulatedText: String = ""
  private var minLength: Int
  
  init(minLength: Int) {
    self.minLength = minLength
  }
  
  func onMessageReceived(text: String) {
    accumulatedText += text
  }
  
  func flush(all: Bool, completionHandler: (String) -> Void) {
    guard all == false else {
      let text = accumulatedText
      reset()
      completionHandler(text)
      return
    }
    
    // Define a character set containing punctuation characters
    let punctuationSet = CharacterSet.punctuationCharacters

    // Find the range of the first occurrence of any punctuation character
    let rangeOfPunctuation: Range<String.Index>? = accumulatedText.rangeOfCharacter(from: punctuationSet)
    
    if let punctuationRange = rangeOfPunctuation {
      let text = accumulatedText[..<punctuationRange.lowerBound]
      let indexAfterPunctuation = accumulatedText.index(after: punctuationRange.lowerBound)
      accumulatedText = String(accumulatedText[indexAfterPunctuation...])
      completionHandler(String(text))
    }
  }

  func reset() {
    accumulatedText = ""
  }
}
