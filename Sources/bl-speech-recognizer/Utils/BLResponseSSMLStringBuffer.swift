//
//  BLResponseSSMLStringBuffer.swift
//  butler-ios
//
//  Created by Daniel Vela on 9/5/24.
//

import Foundation

class BLResponseSSMLStringBuffer {
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
    
    // Find the range of the first occurrence of "</speak>"
    if let range = accumulatedText.range(of: "</speak>") {
      // Calculate the length of the text to flush
      let flushLength = accumulatedText.distance(from: accumulatedText.startIndex, to: range.upperBound)
      
      // Only flush if the chunk meets the minimum length
      if flushLength >= minLength {
        let text = String(accumulatedText[..<range.upperBound])
        accumulatedText = String(accumulatedText[range.upperBound...])
        completionHandler(text)
      }
    }
  }

  func reset() {
    accumulatedText = ""
  }
}
