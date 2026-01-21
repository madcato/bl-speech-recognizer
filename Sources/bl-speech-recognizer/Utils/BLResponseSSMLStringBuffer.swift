//
//  BLResponseSSMLStringBuffer.swift
//  butler-ios
//
//  Created by Daniel Vela on 9/5/24.
//

import Foundation

class BLResponseSSMLStringBuffer: BLStringBuffer {
  var accumulatedText: String = ""
  private var minLength: Int
  
  /// Maximum buffer before forcing a partial flush
  private var maxBufferLength: Int = 200
  
  init(minLength: Int) {
    self.minLength = minLength
  }
  
  func onMessageReceived(text: String) {
    accumulatedText += text
  }
  
  func flush(all: Bool, completionHandler: (String) -> Void) {
    guard all == false else {
      let text = accumulatedText
      accumulatedText = ""
      if !text.isEmpty {
        completionHandler(text)
      }
      return
    }
    
    // Strategy 1: Find complete SSML blocks (</speak> tags)
    if let range = accumulatedText.range(of: "</speak>") {
      let flushLength = accumulatedText.distance(from: accumulatedText.startIndex, to: range.upperBound)
      
      if flushLength >= minLength {
        let text = String(accumulatedText[..<range.upperBound])
        accumulatedText = String(accumulatedText[range.upperBound...])
        completionHandler(text)
        return
      }
    }
    
    // Strategy 2: If buffer is very long without a complete SSML block,
    // look for partial break tags or sentence boundaries within SSML
    if accumulatedText.count > maxBufferLength {
      // Try to find a <break/> tag as a flush point
      if let breakRange = accumulatedText.range(of: "/>", options: .backwards) {
        // Make sure we're not splitting in the middle of a tag
        let potentialText = String(accumulatedText[..<breakRange.upperBound])
        if isValidSSMLFragment(potentialText) && potentialText.count >= minLength {
          accumulatedText = String(accumulatedText[breakRange.upperBound...])
          completionHandler(potentialText)
          return
        }
      }
    }
  }
  
  /// Checks if the SSML fragment is valid (has balanced tags or is standalone)
  private func isValidSSMLFragment(_ text: String) -> Bool {
    // Basic check: count opening and closing speak tags
    let openCount = text.components(separatedBy: "<speak").count - 1
    let closeCount = text.components(separatedBy: "</speak>").count - 1
    
    // Valid if balanced or if it ends with a self-closing tag
    return openCount == closeCount || text.hasSuffix("/>")
  }
}
