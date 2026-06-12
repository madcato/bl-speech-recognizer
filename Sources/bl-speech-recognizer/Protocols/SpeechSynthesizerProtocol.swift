import Foundation

/// Protocol defining the delegate for speech synthesis events.
public protocol BLSpeechSynthesizerDelegate: AnyObject {
  func synthesizerStarted()
  func synthesizerFinished()
  func synthesizing(range: NSRange)
}

/// Protocol defining the interface for speech synthesis.
public protocol SpeechSynthesizerProtocol {
  func speak(_ text: String, isFinal: Bool, voice: Voice?)
  func pause()
  func resume()
  func stop()
}
