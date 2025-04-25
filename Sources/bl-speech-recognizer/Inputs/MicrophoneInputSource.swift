//
//  MicrophoneInputSource.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Speech

/// A class that handles the microphone input source for speech recognition.
class MicrophoneInputSource: InputSource {
  /// Audio Engine to recieve data from the michrophone
  /// Audio Engine to receive data from the microphone
  private var audioEngine: AVAudioEngine = AVAudioEngine()
  
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? = nil
  
  private var speakDetectedCallBack: (() -> Void)?
  
  init(speakDetected: (() -> Void)? = nil) {
    self.speakDetectedCallBack = speakDetected
  }
  /// Initializes the microphone input by configuring the audio session.
  func initialize() throws -> SFSpeechRecognitionRequest? {
    configureAudioSession()
    
    audioEngine = AVAudioEngine()
    audioEngine.isAutoShutdownEnabled = false

    // Echo handling (AEC)
    if #available(iOS 16.0, *) {
      try audioEngine.inputNode.setVoiceProcessingEnabled(true)
      try audioEngine.outputNode.setVoiceProcessingEnabled(true)
    }
    // End Echo handling (AEC)
    
    self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    let inputNode = audioEngine.inputNode
    inputNode.isVoiceProcessingAGCEnabled = true
    
    /// Check if the input node can provide audio data
    if(inputNode.inputFormat(forBus: 0).channelCount == 0) {
      throw SpeechRecognizerError.notAvailableInputs
    }
    /// Set up the format for recording and add a tap to the audio engine's input node
    let recordingFormat = inputNode.outputFormat(forBus: 0)  // 11
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [self] (buffer, _) in
      self.recognitionRequest?.append(buffer)
      
      // Calcula el nivel RMS para detectar actividad sonora.
      if let channelData = buffer.floatChannelData {
        var sum: Float32 = 0.0
        for i in 0..<Int(buffer.frameLength) {
          sum += fabs(channelData.pointee[i])
        }
        let average = sum / Float32(buffer.frameLength)
        
        // Define un umbral para detectar cuando el usuario habla.
        let threshold: Float32 = 0.05
        
        if average > threshold {
//          print("¡Hablando!")
          speakDetectedCallBack?()
        }
      }
    }
    
    /// Prepare and start the audio engine
    audioEngine.prepare()  // 12
    try audioEngine.start()
    
    return recognitionRequest
  }
  
  /// Stops the audio engine and removes any installed taps.
  func stop() {
    recognitionRequest?.endAudio()
    audioEngine.stop()
    if let inputNode = audioEngine.inputNode as? AVAudioInputNode {
      inputNode.removeTap(onBus: 0)
    }
    //    audioEngine.inputNode.reset()
    recognitionRequest = nil
  }
  
  /// Configure the audio session specifically for capturing spoken audio.
  /// This method sets the category, mode, and options for best results during speech capture.
  func configureAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()

    do {
      try audioSession.setCategory(AVAudioSession.Category.playAndRecord,
                                   mode: .voiceChat,
                                   options: [.allowBluetooth, .defaultToSpeaker, .allowAirPlay, .allowBluetoothA2DP])
#if os(watchOS)
    audioSession.activate(completionHandler: { done, error in
      if let error = error {
        print(SpeechRecognizerError.auidoPropertiesError.message)
      }
    })
#elseif !os(macOS)
      if #available(iOS 18.2, *) {
        print("AVAudioSessionCancelledInputAvailable: \(audioSession.isEchoCancelledInputAvailable)")
        
        if audioSession.isEchoCancelledInputAvailable {
          try audioSession.setPrefersEchoCancelledInput(true)
        }
      }
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
#endif
    } catch {
      // Logs an error if audio session properties can't be set
      print(SpeechRecognizerError.auidoPropertiesError.message)
    }
  }
}
