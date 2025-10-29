//
//  InterruptibleChat.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Foundation
import AVFoundation

public protocol InterruptibleChatProtocol {
  @MainActor
  func start(completion: @escaping ((Result<InterruptibleChat.Completion, Error>) -> Void),
                    event: ((InterrumpibleChatEvent) -> Void)?)
  @MainActor
  func stop()
  @MainActor
  func synthesize(text: String, isFinal: Bool)
  @MainActor
  func synthesize(text: String, isFinal: Bool, voice: Voice, activateSSML: Bool)
  @MainActor
  func stopSynthesizing()
  static func listVoices() -> [Voice]
}

public enum InterrumpibleChatEvent {
  case startedListening
  case stoppedListening
  case startedSpeaking
  case stoppedSpeaking
  case detectedSpeaking
  case synthesizingRange(NSRange)
}

//protocol AudioCoordinatorProtocol: SpeechRecognizerProtocol, SpeechSynthesizerProtocol {
//}

/// The `InterruptibleChat` class is responsible for handling continuous speech recognition.
/// Also can synthesize text to speech. If user speaks while synthesizing, it becomes stopped.
/// The text to be synthesize can be added as a stream. This class store the text to be synthesized.
/// It can be used in long interactions with the user, like a chat.
/// It manages the lifecycle of speech recognition using a `BLSpeechRecognizer` instance and informs the client of results and events.
public class InterruptibleChat: InterruptibleChatProtocol, @unchecked Sendable {
  public struct Completion {
    public let text: String
    public let isFinal: Bool
  }
  
  // The speech recognizer responsible for interpreting audio input.
  private var speechRecognizer: BLSpeechRecognizer
  // The speech synthesizer responsible for interpreting audio output.
  private var speechSynthesizer: BLSpeechSynthesizer
  
  // Closure to be called upon completion with the recognition result or an error.
  private var completion: ((Result<InterruptibleChat.Completion, Error>) -> Void)!
  // Closure to be called upon an event appears
  private var eventLaunch: ((InterrumpibleChatEvent) -> Void)?
  
  private var detectedSpeech = ""
  private var timer: Timer?
  /// Time to detect silence before considering the speech as final.
  private var waitTime: TimeInterval = 1.0
  
  // Audio device monitoring properties
  private var deviceChangeObserver: NSObjectProtocol?
  private var lastKnownInputDevice: String?
  private var isMonitoringDevices = false
  private var inputType: InputSourceType
  private var locale: Locale
  private var activateSSML: Bool
  
  public init(inputType: InputSourceType, locale: Locale = .current, activateSSML: Bool) {
    // Store initialization parameters for potential device restarts
    self.inputType = inputType
    self.locale = locale
    self.activateSSML = activateSSML
    
    // Synthesizer construction
    speechSynthesizer = BLSpeechSynthesizer(activateSSML: activateSSML)
    
    // Recognizer construction
    let inputSource = InputSourceFactory.create(inputSource: inputType)
    speechRecognizer = BLSpeechRecognizer(inputSource: inputSource, locale: locale, shouldReportPartialResults: true, task: .query)
    
    // Delegates
    speechSynthesizer.delegate = self
    speechRecognizer.delegate = self
    
    // Setup audio device monitoring
    setupAudioDeviceMonitoring()
  }
  
  deinit {
    stopAudioDeviceMonitoring()
  }
  
  /// Starts the speech recognition process.
  ///
  /// - Parameters:
  ///   - inputType: The type of input source to be used for speech recognition. Possible values:
  ///   - locale: The locale specifying language and regional settings, defaults to current locale.
  ///   - completion: A closure to be executed with the result of the recognition or an error.
  @MainActor
  public func start(completion: @escaping ((Result<InterruptibleChat.Completion, Error>) -> Void),
                    event: ((InterrumpibleChatEvent) -> Void)? = nil) {
    self.completion = completion
    self.eventLaunch = event
    
    // Configure audio session for better device change handling
    configureAudioSession()
    
    // Update last known input device and start monitoring
    lastKnownInputDevice = AudioDeviceMonitor.getCurrentInputDevice()
    isMonitoringDevices = true
    
    // Starts the recognition process.
    speechRecognizer.start()
  }
  
  /// Stops the speech recognition process and cleans up resources.
  @MainActor
  public func stop() {
    // Stop monitoring devices
    isMonitoringDevices = false
    
    // Stop the speech recognizer.
    speechRecognizer.stop()
  }
  
  /// Starts or continues the speech synthesizing process and cleans up resources.
  @MainActor
  public func synthesize(text: String, isFinal: Bool) {
    speechSynthesizer.speak(text, isFinal: isFinal)
  }
  
  @MainActor
  public func synthesize(text: String, isFinal: Bool, voice: Voice, activateSSML: Bool = false) {
    speechSynthesizer.speak(text, isFinal: isFinal, voice: voice)
  }
  
  /// Stops the speech synthesizing process and cleans up resources.
  @MainActor
  public func stopSynthesizing() {
    speechSynthesizer.stop()
  }
  
  /// List all available voices
  public static func listVoices() -> [Voice] {
    return BLSpeechSynthesizer.availableVoices()
  }
  
  private func userIsSpeaking() {
    Task.detached {
      await self.stopSynthesizing()
    }
    eventLaunch?(.detectedSpeaking)
  }
  
  // MARK: - Audio Device Management
  
  private func setupAudioDeviceMonitoring() {
    lastKnownInputDevice = AudioDeviceMonitor.getCurrentInputDevice()
    
    #if os(macOS)
    // Start monitoring for macOS
    AudioDeviceMonitor.startMonitoring()
    
    deviceChangeObserver = NotificationCenter.default.addObserver(
      forName: AudioDeviceMonitor.audioDeviceChangedNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      self?.handleMacOSAudioDeviceChange()
    }
    #else
    // Use AVAudioSession for iOS
    deviceChangeObserver = NotificationCenter.default.addObserver(
      forName: AVAudioSession.routeChangeNotification,
      object: AVAudioSession.sharedInstance(),
      queue: .main
    ) { [weak self] notification in
      self?.handleAudioRouteChange(notification)
    }
    #endif
  }
  
  private func stopAudioDeviceMonitoring() {
    if let observer = deviceChangeObserver {
      NotificationCenter.default.removeObserver(observer)
      deviceChangeObserver = nil
    }
    #if os(macOS)
    AudioDeviceMonitor.stopMonitoring()
    #endif
  }
  
  #if os(macOS)
  private func handleMacOSAudioDeviceChange() {
    guard isMonitoringDevices else { return }
    
    print("[InterruptibleChat] macOS audio device changed")
    
    let currentInputDevice = AudioDeviceMonitor.getCurrentInputDevice()
    if currentInputDevice != lastKnownInputDevice {
      print("[InterruptibleChat] Input device changed from '\(lastKnownInputDevice ?? "nil")' to '\(currentInputDevice ?? "nil")'")
      lastKnownInputDevice = currentInputDevice
      
      // Restart recognition to use the new device
      restartRecognition()
    }
  }
  #endif
  
  #if !os(macOS)
  private func handleAudioRouteChange(_ notification: Notification) {
    guard isMonitoringDevices else { return }
    
    guard let userInfo = notification.userInfo,
          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
      return
    }
    
    print("[InterruptibleChat] Audio route changed: \(reason)")
    
    // Check if input device changed
    let currentInputDevice = AudioDeviceMonitor.getCurrentInputDevice()
    if currentInputDevice != lastKnownInputDevice {
      print("[InterruptibleChat] Input device changed from '\(lastKnownInputDevice ?? "nil")' to '\(currentInputDevice ?? "nil")'")
      lastKnownInputDevice = currentInputDevice
      
      // Restart recognition to use the new device
      restartRecognition()
    }
  }
  #endif
  
  private func restartRecognition() {
    Task { @MainActor in
      // Store current completion and event handlers
      let currentCompletion = self.completion
      let currentEvent = self.eventLaunch
      
      // Stop current recognition
      speechRecognizer.stop()
      
      // Small delay to ensure clean stop
      try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
      
      // Recreate the speech recognizer with new device
      let inputSource = InputSourceFactory.create(inputSource: self.inputType)
      speechRecognizer = BLSpeechRecognizer(inputSource: inputSource, locale: self.locale, shouldReportPartialResults: true, task: .query)
      speechRecognizer.delegate = self
      
      // Restore handlers
      self.completion = currentCompletion
      self.eventLaunch = currentEvent
      
      // Update device info
      lastKnownInputDevice = AudioDeviceMonitor.getCurrentInputDevice()
      
      // Start recognition again
      speechRecognizer.start()
      
      print("[InterruptibleChat] Recognition restarted with new input device")
    }
  }
  
  private func configureAudioSession() {
    #if !os(macOS)
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
      try audioSession.setActive(true)
      print("[InterruptibleChat] Audio session configured")
    } catch {
      print("[InterruptibleChat] Failed to configure audio session: \(error.localizedDescription)")
    }
    #endif
  }
}

// MARK: - BLSpeechRecognizerDelegate

extension InterruptibleChat: @preconcurrency BLSpeechRecognizerDelegate {
  @MainActor func recognized(text: String, isFinal: Bool) {
    self.detectedSpeech = text
    
    switch isFinal {
    case true:
      self.completion(.success(.init(text: self.detectedSpeech, isFinal: true)))
      self.detectedSpeech = ""
      break
    case false:
      userIsSpeaking()
//      self.timer?.invalidate()
//      self.timer = Timer.scheduledTimer(withTimeInterval: self.waitTime, repeats: false, block: { timer in
//        self.completion(.success(.init(text: self.detectedSpeech, isFinal: true)))
//        self.detectedSpeech = ""
//      })
    }
//    print("[org.veladan.voice] thread id: \(Thread.current), recognized speech: \(text)")
  }
  
  func started() {
    eventLaunch?(.startedListening)
  }
  
  func finished() {
    eventLaunch?(.stoppedListening)
  }
  
  func speechRecognizer(available: Bool) {
    // TODO: Notify the client of availability change
  }
  
  func speechRecognizer(error: any Error) {
    completion?(.failure(error))
  }
}

extension InterruptibleChat: BLSpeechSynthesizerDelegate {
  func synthesizerStarted() {
    eventLaunch?(.startedSpeaking)
  }
  
  func synthesizerFinished() {
    eventLaunch?(.stoppedSpeaking)
  }
  
  func synthesizing(range: NSRange) {
    eventLaunch?(.synthesizingRange(range))
  }
  
}

// MARK: - InterruptibleChat mock

public class InterruptibleChatMock: InterruptibleChatProtocol {
  private var completion: ((Result<InterruptibleChat.Completion, Error>) -> Void)!
  // Closure to be called upon an event appears
  private var eventLaunch: ((InterrumpibleChatEvent) -> Void)?
  
  private let recognized: [String]
  public var speaked: String = ""
  
  public init(recognized: [String]) {
    self.recognized = recognized
  }
  
  @MainActor
  public func start(completion: @escaping ((Result<InterruptibleChat.Completion, Error>) -> Void),
             event: ((InterrumpibleChatEvent) -> Void)?) {
    self.completion = completion
    self.eventLaunch = event
    
    self.eventLaunch?(.startedListening)
    for text in recognized {
      self.eventLaunch?(.detectedSpeaking)
      self.completion(.success(.init(text: text, isFinal: false)))
    }
    
    self.completion(.success(.init(text: "", isFinal: true)))
  }
  
  @MainActor
  public func stop() {
    self.eventLaunch?(.stoppedListening)
  }
  
  @MainActor
  public func synthesize(text: String, isFinal: Bool) {
    self.eventLaunch?(.startedSpeaking)
    self.speaked.append(text)
  }
  
  @MainActor
  public func synthesize(text: String, isFinal: Bool, voice: Voice, activateSSML: Bool) {
    self.eventLaunch?(.startedSpeaking)
    self.speaked.append(text)
  }
  
  @MainActor
  public func stopSynthesizing() {
    self.eventLaunch?(.stoppedSpeaking)
  }
  
  public static func listVoices() -> [Voice] {
    return [Voice(language: "en_US", identifier: "voice_id", name: "The Voice", gender: .male, quality: .default)]
  }
}
