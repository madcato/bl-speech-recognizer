import Foundation

public protocol BLSpeechRecognizerDelegate: AnyObject {
  func recognized(text: String, isFinal: Bool)
  func started()
  func finished()
  func speechRecognizer(available: Bool)
  func speechRecognizer(error: Error)
}

public protocol BLSpeechRecognizerInput {
  func requestAuthorization(_ onFinish: @escaping (Result<Bool, Error>) throws -> Void)
  func start()
  func resume()
  func pause()
}
