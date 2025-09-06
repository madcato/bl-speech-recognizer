//
//  BLStringBuffer.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 6/9/25.
//

//
//  BLResponseSSMLStringBuffer.swift
//  butler-ios
//
//  Created by Daniel Vela on 9/5/24.
//

import Foundation

protocol BLStringBuffer {
  var accumulatedText: String { get set }
  func onMessageReceived(text: String)
  func flush(all: Bool, completionHandler: (String) -> Void)
}

extension BLStringBuffer {
  mutating func reset() {
    self.accumulatedText = ""
  }
}
