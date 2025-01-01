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
  private let audioEngine: AVAudioEngine = AVAudioEngine()
  
  /// Initializes the microphone input by configuring the audio session.
  func initialize() {
    configureAudioSession()
  }
  
  /// Configures the audio engine with the given speech recognition request.
  /// - Parameter recognitionRequest: The recognition request that will receive audio buffers.
  /// - Throws: `SpeechRecognizerError.notAvailableInputs` if no audio inputs are available.
  func configure(with recognitionRequest: SFSpeechAudioBufferRecognitionRequest?) throws {
    let inputNode = audioEngine.inputNode
    
    /// Check if the input node can provide audio data
    if(inputNode.inputFormat(forBus: 0).channelCount == 0) {
      throw SpeechRecognizerError.notAvailableInputs
    }
    /// Set up the format for recording and add a tap to the audio engine's input node
    let recordingFormat = inputNode.outputFormat(forBus: 0)  // 11
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
      recognitionRequest?.append(buffer)
    }

    /// Prepare and start the audio engine
    audioEngine.prepare()  // 12
    try audioEngine.start()
  }
  
  /// Stops the audio engine and removes any installed taps.
  func stop() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    audioEngine.inputNode.reset()
  }
  
  /// Configures the audio session specifically for capturing spoken audio.
  /// This method sets the category, mode, and options for best results during speech capture.
  func configureAudioSession() {
#if !os(macOS)
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(AVAudioSession.Category.playAndRecord,
                                   mode: .spokenAudio,
                                   options: [.allowBluetoothA2DP, .allowBluetooth, .allowAirPlay, .defaultToSpeaker])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      // Logs an error if audio session properties can't be set
      print(SpeechRecognizerError.auidoPropertiesError.message)
    }
#endif
  }
}
