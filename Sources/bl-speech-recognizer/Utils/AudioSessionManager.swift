//
//  AudioSessionManager.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 21/1/26.
//

import AVFoundation
#if os(macOS)
import CoreAudio
#endif

/// A utility class that handles audio session configuration for speech recognition.
/// This consolidates audio session setup logic used by both MicrophoneInputSource and VoiceChatbotRecognizer.
class AudioSessionManager {
  
  /// Configuration options for the audio session
  struct Configuration {
    /// Whether to detect Bluetooth and conditionally set defaultToSpeaker
    var detectBluetooth: Bool = true
    /// Whether to enable echo cancellation when available
    var enableEchoCancellation: Bool = true
    
    static let `default` = Configuration()
  }
  
#if !os(macOS)
  /// Returns whether Bluetooth audio is currently connected
  static func isBluetoothConnected() -> Bool {
    let audioSession = AVAudioSession.sharedInstance()
    return audioSession.currentRoute.outputs.contains { output in
      output.portType == .bluetoothHFP || output.portType == .bluetoothA2DP
    }
  }
#endif
  
  /// Configures the audio session for speech recognition.
  /// - Parameter configuration: Configuration options for the audio session
  /// - Throws: SpeechRecognizerError if audio session configuration fails
  static func configureAudioSession(configuration: Configuration = .default) throws {
#if !os(macOS)
    let audioSession = AVAudioSession.sharedInstance()
    
    var options: AVAudioSession.CategoryOptions = [
      .allowBluetoothHFP,     // Allow Hands Free Devices
      .allowBluetoothA2DP,    // AirPods, high-quality auriculars
      .allowAirPlay,          // AirPods Pro/Max/etc
      .duckOthers             // Lower other apps volume
      // .mixWithOthers       // Optional: if you want to mix with other apps
    ]
    
    // Detect if Bluetooth is connected (or AirPods)
    if configuration.detectBluetooth {
      let bluetoothConnected = isBluetoothConnected()
      if !bluetoothConnected {
        // Only force speaker when NOT Bluetooth connected → avoids breaking mic of AirPods
        options.insert(.defaultToSpeaker)
      }
    }
    
    do {
      try audioSession.setCategory(
        AVAudioSession.Category.playAndRecord,
        mode: .voiceChat,
        options: options
      )
      
#if os(watchOS)
      audioSession.activate { done, error in
        if let error = error {
          print(SpeechRecognizerError.audioPropertiesError.localizedDescription)
        }
      }
#else
      // Enable echo cancellation if available (iOS 18.2+)
      if configuration.enableEchoCancellation {
        if #available(iOS 18.2, *) {
          print("AVAudioSessionCancelledInputAvailable: \(audioSession.isEchoCancelledInputAvailable)")
          
          if audioSession.isEchoCancelledInputAvailable {
            try audioSession.setPrefersEchoCancelledInput(true)
          }
        }
      }
      
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
#endif
    } catch {
      throw SpeechRecognizerError.audioPropertiesError(error.localizedDescription)
    }
#endif
  }
  
  /// Deactivates the audio session
  static func deactivateAudioSession() {
#if !os(macOS)
    do {
      try AVAudioSession.sharedInstance().setActive(false)
    } catch {
      print("Error deactivating audio session: \(error)")
    }
#endif
  }
  
  /// Configures voice processing on an audio engine's input node.
  /// - Parameters:
  ///   - audioEngine: The audio engine to configure
  ///   - enableAGC: Whether to enable Automatic Gain Control when voice processing is active
  /// - Returns: Whether voice processing was successfully enabled
  @discardableResult
  static func configureVoiceProcessing(
    on audioEngine: AVAudioEngine,
    enableAGC: Bool = true
  ) -> Bool {
#if !os(macOS)
    var voiceProcessingEnabled = false
    
    // Skip voice processing if Bluetooth is connected to avoid breaking mic
    if isBluetoothConnected() {
      print("[AudioSessionManager] Bluetooth connected, skipping voice processing")
      return false
    }
    
    if #available(iOS 16.0, macOS 14.0, *) {
      do {
        try audioEngine.inputNode.setVoiceProcessingEnabled(true)
        voiceProcessingEnabled = true
        
        if #available(iOS 17.0, macOS 14.0, *) {
          audioEngine.inputNode.voiceProcessingOtherAudioDuckingConfiguration =
            AVAudioVoiceProcessingOtherAudioDuckingConfiguration(
              enableAdvancedDucking: true,
              duckingLevel: .max
            )
        }
        print("[AudioSessionManager] Voice processing enabled successfully")
      } catch {
        print("[AudioSessionManager] Voice processing failed, disabling: \(error)")
        voiceProcessingEnabled = false
      }
    }
    
    // Only enable AGC if voice processing is active
    if voiceProcessingEnabled && enableAGC {
      audioEngine.inputNode.isVoiceProcessingAGCEnabled = true
    }
    
    return voiceProcessingEnabled
#else
    return false
#endif
  }
}
