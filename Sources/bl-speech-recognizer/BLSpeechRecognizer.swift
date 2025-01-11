//
//  BLSpeechRecognizer.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Speech

protocol BLSpeechRecognizerDelegate: AnyObject {
  /// Called when speech recognition has recognized text.
  ///
  /// - Parameters:
  ///   - text: The recognized text. This value is empty string, when `isFinal` is **true**.
  ///   - isFinal: Boolean indicating if the recognition result is final.
  func recognized(text: String, isFinal: Bool)
  /// Called when the speech recognition has started.
  func started()
  /// Called when the speech recognition has finished.
  func finished()
  /// Called when the availability of the speech recognizer changes.
  ///
  /// - Parameter available: Boolean indicating if the recognizer is available.
  func speechRecognizer(available: Bool)
  /// Called when an error occurs during speech recognition.
  ///
  /// - Parameter error: The error occurred during recognition.
  func speechRecognizer(error: Error)
}

protocol BLSpeechRecognizerInput {
  func requestAuthorization(_ onFinish: @escaping (Bool) -> Void)
  func start()
  func resume()
  func pause()
}

enum BLTaskType {
  /// Use this when the recognition requires more than a few seconds or undefined time
  case dictation
  /// Use this when it's expected a few words, like: "search for previous documents", "yes"
  case query
  
  var convert: SFSpeechRecognitionTaskHint {
    switch self {
    case .dictation:
      return .dictation
    case .query:
      return .search
    }
  }
}

final class BLSpeechRecognizer: NSObject {
  public weak var delegate: BLSpeechRecognizerDelegate?
  
  /// Recognizer
  let speechRecognizer: SFSpeechRecognizer!
  
  /// Request input object
  private var recognitionRequest: SFSpeechRecognitionRequest?
  /// Recognizing task object
  private var recognitionTask: SFSpeechRecognitionTask?
  /// time to wait
  private let waitTime: Double!
  /// type of regcognition task, default is unspeciified
  private let taskType: BLTaskType?
  /// Input source: can be microphone or cust,
  /// If custom, all the input must be provided by using method process
  private var inputSource: InputSource
  
  public init(inputSource: InputSource, locale: Locale = .current, wait time: Double? = 0.8, task taskType: BLTaskType? = nil) throws {
    self.waitTime = time
    self.taskType = taskType
    self.inputSource = inputSource
    guard let recognizer = SFSpeechRecognizer(locale: locale) else {
      throw SpeechRecognizerError.speechRecognizerNotAvailable
    }
    self.speechRecognizer = recognizer
  }
  
  func requestAuthorization(_ onFinish: @escaping (Result<Bool, Error>) throws -> Void) {
    SFSpeechRecognizer.requestAuthorization { authStatus in
      do {
        switch authStatus {
        case .authorized:
          try onFinish(.success(true))
        case .denied:
          try onFinish(.failure(SpeechRecognizerError.userDenied))
        case .restricted:
          try onFinish(.failure(SpeechRecognizerError.recognitionRestricted))
        case .notDetermined:
          try onFinish(.failure(SpeechRecognizerError.notDetermined))
        @unknown default:
          fatalError("Unknown case")
        }
      } catch {
        self.delegate?.speechRecognizer(error: error)
      }
    }
  }
  
  @MainActor
  public func start() {
    self.speechRecognizer.delegate = self
    requestAuthorization { isOk in
      switch isOk {
      case .success:
        guard self.speechRecognizer.isAvailable else {
          throw SpeechRecognizerError.speechRecognizerNotAvailable
        }
        
        DispatchQueue.main.async {
          do{
            try self.startRecognition()
          } catch {
            self.delegate?.speechRecognizer(error: error)
          }
        }
      case .failure(let error):
        throw error
      }
    }
  }
  
  @MainActor
  public func stop() {
    stopRecognition()
  }
  
  @MainActor
  private func startRecognition() throws {
    guard Thread.isMainThread else {
      fatalError("Must be called from main thread")
    }
    recognitionRequest = try self.inputSource.initialize()  //3
    guard let recognitionRequest = recognitionRequest else {
      throw SpeechRecognizerError.recognitionTaskUnable
    } //5
    recognitionRequest.shouldReportPartialResults = true  //6
    recognitionRequest.taskHint = taskType?.convert ?? SFSpeechRecognitionTaskHint.unspecified
    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest,
                                                       resultHandler: { (result, error) in  //7
      if let error = error {
        if error.localizedDescription == "Error" {
#if DEBUG
          print(error.localizedDescription)
#endif
          self.clean()
          // This error happends after one minute of inactivity.
          // Resume
          //          let waitSeconds = 1.0
          //          DispatchQueue.main.asyncAfter(deadline: .now() + waitSeconds) {
          //            self.startRecording()
          //          }
        } else {
          self.inputSource.stop()
          print(error.localizedDescription)
        }
        return
      }
      
      if let result = result {
        let transcription = result.bestTranscription
        self.delegate?.recognized(text: transcription.formattedString, isFinal: result.isFinal)
      }
    }
    )
  }
  
  private func stopRecognition() {
    recognitionTask?.cancel()
    recognitionTask = nil
    inputSource.stop()
    recognitionRequest = nil
  }
  
  private func clean() {
    inputSource.stop()
    recognitionRequest = nil
    recognitionTask?.cancel()
    recognitionTask = nil
    //    innerRestart()
  }
}

extension BLSpeechRecognizer: SFSpeechRecognizerDelegate {
  public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
    delegate?.speechRecognizer(available: available)
  }
}

//  @objc private func innerRestart() {
//    DispatchQueue.main.async {
//      if self.doRestart {
//        self.doRestart = false
//        self.start()
//      }
//    }
//  }

