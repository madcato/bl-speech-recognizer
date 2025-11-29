//
//  MicrophoneInputSource.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Speech
import AVFoundation
import AudioToolbox
#if os(macOS)
import CoreAudio
#endif

/// A class that handles the microphone input source for speech recognition.
class MicrophoneInputSource: InputSource {
  /// Audio Engine to receive data from the microphone
  private var audioEngine: AVAudioEngine = AVAudioEngine()
  private let audioQueue = DispatchQueue(label: "com.example.audioProcessing", qos: .userInitiated)
  
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? = nil
  
  private var speakDetectedCallBack: (() -> Void)?
  private var silenceDetectedCallBack: (() -> Void)?
  
  // Audio device change handling
  private var isInitialized = false
  
  private let speakThreshold: Float32 = -15.0
  private let silenceThreshold: Float32 = -50.0
  private var accumulatedSilence: Double = 0
  private var timeToLaunchSilenceEvent: Double // seconds
  
  init(speakDetected: (() -> Void)? = nil, silenceDetected: (() -> Void)? = nil, timeToLaunchSilenceEvent: Double = 0.5) {
    self.speakDetectedCallBack = speakDetected
    self.silenceDetectedCallBack = silenceDetected
    self.timeToLaunchSilenceEvent = timeToLaunchSilenceEvent
    
    // Set up audio device change notifications
    setupAudioDeviceChangeNotifications()
  }
  
  deinit {
    removeAudioDeviceChangeNotifications()
  }
  /// Initializes the microphone input by configuring the audio session.
  func initialize() throws -> SFSpeechRecognitionRequest? {
    try initializeAudioEngine()
    isInitialized = true
    return recognitionRequest
  }
  
  /// Internal method to initialize or reinitialize the audio engine
  private func initializeAudioEngine() throws {
    configureAudioSession()
    
    audioEngine = AVAudioEngine()
    audioEngine.isAutoShutdownEnabled = false
    
    // AEC
//    var voiceProcessingEnabled = false
//    if #available(iOS 16.0, *) {
//  #if !os(macOS)
//      do {
//        try audioEngine.inputNode.setVoiceProcessingEnabled(true)
//        voiceProcessingEnabled = true
//        if #available(iOS 17.0, macOS 14, *) {
//          audioEngine.inputNode.voiceProcessingOtherAudioDuckingConfiguration = AVAudioVoiceProcessingOtherAudioDuckingConfiguration(enableAdvancedDucking: true, duckingLevel: .max)
//        }
//      } catch {
//        print("[MicrophoneInputSource] Voice processing failed, disabling: \(error)")
//        voiceProcessingEnabled = false
//      }
//  #endif
//    }
    
    
    self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    let inputNode = audioEngine.inputNode
    inputNode.isVoiceProcessingAGCEnabled = true
    
    let ibuses = inputNode.numberOfInputs
    let obuses = inputNode.numberOfOutputs
    
    print("Number of Inputs: \(ibuses)")
    print("Number of Outputs: \(obuses)")
    
    /// Check if the input node can provide audio data
    if(inputNode.inputFormat(forBus: 0).channelCount == 0) {
      throw SpeechRecognizerError.notAvailableInputs
    }
    /// Set up the format for recording and add a tap to the audio engine's input node
    let recordingFormat = inputNode.outputFormat(forBus: 0)  // 11
    guard recordingFormat.sampleRate > 0 else {
      throw SpeechRecognizerError.audioInputFailure("Invalid audio format: Sample rate is 0 Hz. Don't use iOS Simulator.")
    }
    inputNode.installTap(onBus: 0, bufferSize: 16384, format: recordingFormat) { [weak self] (buffer, _) in
      self?.audioQueue.async {
        guard buffer.frameLength > 0, let channelData = buffer.floatChannelData?[0] else {
          print("Invalid audio buffer, skipping")
          return
        }
        self?.recognitionRequest?.append(buffer)
      }
      //      return  // Removing this line, silence and VAD can be detected, but device Energy Impact raises
      //      // Analyze the audio buffer for silence
      //      let frameLength = Int(buffer.frameLength)
      //      guard let channelData = buffer.floatChannelData?[0],
      //            frameLength > 0 else { return }
      //
      //      // Compute RMS (root mean square) of the audio samples
      //      var sumSquares: Float = 0
      //      for i in 0..<frameLength {
      //        let sample = channelData[i]
      //        sumSquares += sample * sample
      //      }
      //      let rms = sqrt(sumSquares / Float(frameLength))
      //      // Convert to dB
      //      let avgPower = 20 * log10(rms)
      //
      //      // How long this buffer covers in seconds
      //      let bufferDuration = Double(buffer.frameLength) / recordingFormat.sampleRate
      //
      //      // If power is below threshold, count it as silence
      //      if avgPower < self.silenceThreshold {
      ////        print("Silencio")
      //        self.accumulatedSilence += bufferDuration
      //        // If we've had at least 1 second of silence, fire the callback once
      //        if self.accumulatedSilence >= timeToLaunchSilenceEvent {
      //          // Reset so we don't call repeatedly
      ////          print("[org.veladan.voice] thread id: --> \(Thread.current)")
      //          self.accumulatedSilence = 0
      //          self.silenceDetectedCallBack?()
      //        }
      //      } else {
      //        // Reset the counter on any non-silent audio
      //        self.accumulatedSilence = 0
      //      }
      //
      //      // Speak detection callback
      ////      print("[org.veladan.voice] avgPower: \(avgPower), speakThreshold: \(speakThreshold), silenceThreshold: \(silenceThreshold)")
      //      if avgPower > speakThreshold {
      ////        print("org.veladan.voice ¡Hablando!")
      //        speakDetectedCallBack?()
      //        self.accumulatedSilence = 0
      //      }
    }
    
    /// Prepare and start the audio engine
    audioEngine.prepare()  // 12
    try audioEngine.start()
    
    print("[MicrophoneInputSource] Audio engine started successfully")
  }
  
  /// Handles audio device changes by reinitializing the audio engine
//  private func handleAudioDeviceChange() {
//    print("[MicrophoneInputSource] Audio device change detected")
//    
//    guard isInitialized else { return }
//    
//    // Restart audio engine on main queue to avoid race conditions
//    DispatchQueue.main.async { [weak self] in
//      self?.restartAudioEngine()
//    }
//  }
  
  /// Restarts the audio engine when device changes occur
  private func restartAudioEngine() {
    print("[MicrophoneInputSource] Restarting audio engine due to device change")
    
    // Stop current engine
    stopAudioEngine()
    
    // Small delay to allow device switching to complete
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      do {
        try self?.initializeAudioEngine()
        print("[MicrophoneInputSource] Audio engine restarted successfully")
      } catch {
        print("[MicrophoneInputSource] Failed to restart audio engine: \(error)")
      }
    }
  }
  
  /// Stops the audio engine and removes any installed taps.
  func stop() {
    isInitialized = false
    stopAudioEngine()
  }
  
  /// Stops the audio engine without cleaning up notifications
  func stopAudioEngine() {
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
#if !os(macOS)
    let audioSession = AVAudioSession.sharedInstance()
    
    do {
      try audioSession.setCategory(AVAudioSession.Category.playAndRecord,
                                   mode: .voiceChat,
                                   options: [.defaultToSpeaker])  // [.allowBluetooth, .defaultToSpeaker, .allowAirPlay, .allowBluetoothA2DP])
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
      fatalError(SpeechRecognizerError.auidoPropertiesError(error.localizedDescription).errorDescription ?? "Unknown error.")
    }
#endif
  }
  
  // MARK: - Audio Device Change Notifications
  
  /// Sets up notifications for audio device changes
  func setupAudioDeviceChangeNotifications() {
#if os(macOS)
    // macOS: Use Core Audio notifications for device changes
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultInputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    
    let callback: AudioObjectPropertyListenerProc = { _, _, _, userData in
      if let userData = userData {
        let mutableSelf = Unmanaged<MicrophoneInputSource>.fromOpaque(userData).takeUnretainedValue()
        mutableSelf.handleAudioDeviceChange()
      }
      return noErr
    }
    
    AudioObjectAddPropertyListener(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      callback,
      Unmanaged.passUnretained(self).toOpaque()
    )
    
    // Also listen for output device changes as they can affect routing
    address.mSelector = kAudioHardwarePropertyDefaultOutputDevice
    AudioObjectAddPropertyListener(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      callback,
      Unmanaged.passUnretained(self).toOpaque()
    )
    
    print("[MicrophoneInputSource] Audio device change notifications set up for macOS")
    
#else
    // iOS: Use AVAudioSession notifications
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioSessionRouteChange(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioSessionInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: nil
    )
    
    print("[MicrophoneInputSource] Audio session notifications set up for iOS")
#endif
  }
  
  /// Removes audio device change notifications
  func removeAudioDeviceChangeNotifications() {
#if os(macOS)
    // macOS: Remove Core Audio listeners
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultInputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    
    let callback: AudioObjectPropertyListenerProc = { _, _, _, _ in
      return noErr
    }
    
    AudioObjectRemovePropertyListener(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      callback,
      Unmanaged.passUnretained(self).toOpaque()
    )
    
    address.mSelector = kAudioHardwarePropertyDefaultOutputDevice
    AudioObjectRemovePropertyListener(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      callback,
      Unmanaged.passUnretained(self).toOpaque()
    )
    
    print("[MicrophoneInputSource] Audio device change notifications removed for macOS")
    
#else
    // iOS: Remove notification observers
    NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    
    print("[MicrophoneInputSource] Audio session notifications removed for iOS")
#endif
  }
  
#if !os(macOS)
  /// Handles AVAudioSession route changes (iOS)
  @objc func handleAudioSessionRouteChange(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
      return
    }
    
    print("[MicrophoneInputSource] Audio route change reason: \(reason)")
    
    switch reason {
    case .newDeviceAvailable, .oldDeviceUnavailable, .categoryChange:
      handleAudioDeviceChange()
    default:
      break
    }
  }
  
  /// Handles AVAudioSession interruptions (iOS)
  @objc func handleAudioSessionInterruption(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }
    
    print("[MicrophoneInputSource] Audio interruption type: \(type)")
    
    switch type {
    case .began:
      print("[MicrophoneInputSource] Audio interruption began")
    case .ended:
      print("[MicrophoneInputSource] Audio interruption ended")
      handleAudioDeviceChange()
    @unknown default:
      break
    }
  }
#endif
  
  private var deviceChangeDebounceTimer: Timer?
  
  /// Handles audio device changes by reinitializing the audio engine
  private func handleAudioDeviceChange() {
    print("[MicrophoneInputSource] Audio device change detected")
    
    guard isInitialized else { return }
    
    // NEW: Debounce to avoid rapid restarts
    deviceChangeDebounceTimer?.invalidate()
    deviceChangeDebounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
      Task { await self?.restartAudioEngineAsync() }
    }
  }
  
  private func restartAudioEngineAsync() async {
    print("[MicrophoneInputSource] Restarting audio engine due to device change")
    
    // Stop current engine
    stopAudioEngine()
    
    // Small delay to allow device switching
    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s
    
    do {
      try await initializeAudioEngineAsync()
      print("[MicrophoneInputSource] Audio engine restarted successfully")
    } catch {
      print("[MicrophoneInputSource] Failed to restart audio engine: \(error)")
    }
  }
  
  private func initializeAudioEngineAsync() async throws {
    // Convert initializeAudioEngine to async if needed (wrap in Task)
    try initializeAudioEngine()  // Assuming it's made async
  }
}
