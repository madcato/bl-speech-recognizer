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
  
  func flush(completionHandler: (String) -> Void) {
    let text = accumulatedText
    if minLength < text.count {
      accumulatedText = ""
      completionHandler(text)
    }
  }
  
  func reset() {
    accumulatedText = ""
  }
}
