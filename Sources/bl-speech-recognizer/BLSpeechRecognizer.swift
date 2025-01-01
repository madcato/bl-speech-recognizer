//
//  BLSpeechRecognizer.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Speech

protocol BLSpeechRecognizerDelegate: AnyObject {
  func recognized(text: String, isFinal: Bool)
  func started()
  func finished()
  func speechRecognizer(available: Bool)
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
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  /// Recognizing task object
  private var recognitionTask: SFSpeechRecognitionTask?
  /// Timer used to stop reconging task after some inactivity period
  private var timer: Timer?
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
  
  public func start() {
    self.speechRecognizer.delegate = self
    requestAuthorization { isOk in
      switch isOk {
      case .success:
        guard self.speechRecognizer.isAvailable else {
          throw SpeechRecognizerError.speechRecognizerNotAvailable
        }
        self.inputSource.initialize()
        try self.startRecognition()
      case .failure(let error):
        throw error
      }
    }
  }
  
  public func stop() {
    stopRecognition()
  }
  
  public func processAudio(_ audioBuffer: AVAudioPCMBuffer) {
    recognitionRequest?.append(audioBuffer)
  }
  
  private func startRecognition() throws {
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
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
        
        if self.taskType != .dictation  {
          self.timer?.invalidate()
          if result.isFinal == false {
            self.timer = Timer.scheduledTimer(withTimeInterval: self.waitTime, repeats: false, block: { timer in
              //              self.pause()
            })
          }
        }
      }
    }
    )
    try inputSource.configure(with: recognitionRequest)
  }
  
  private func stopRecognition() {
    recognitionTask?.cancel()
    recognitionTask = nil
    
    inputSource.stop()
    
    recognitionRequest?.endAudio()
    recognitionRequest = nil
  }
  
  private func clean() {
    inputSource.stop()
    recognitionRequest?.endAudio()
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


