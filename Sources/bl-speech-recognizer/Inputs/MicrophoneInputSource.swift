//
//  MicrophoneInputSource.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Speech

class MicrophoneInputSource: InputSource {
  /// Audio Engine to recieve data from the michrophone
  private let audioEngine: AVAudioEngine = AVAudioEngine()
  
  func initialize() {
    configureAudioSession()
  }
  
  func configure(with recognitionRequest: SFSpeechAudioBufferRecognitionRequest?) throws {
    let inputNode = audioEngine.inputNode
    if(inputNode.inputFormat(forBus: 0).channelCount == 0) {
      throw SpeechRecognizerError.notAvailableInputs
    }
    let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
      recognitionRequest?.append(buffer)
    }
    audioEngine.prepare()  //12
    
    try audioEngine.start()
  }
  
  func stop() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    audioEngine.inputNode.reset()
  }
  
  func configureAudioSession() {
#if !os(macOS)
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(AVAudioSession.Category.playAndRecord,
                                   mode: .spokenAudio,
                                   options: [.allowBluetoothA2DP, .allowBluetooth, .allowAirPlay, .defaultToSpeaker])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print(SpeechRecognizerError.auidoPropertiesError.message)
    }
#endif
  }
}
