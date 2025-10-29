//
//  AudioDeviceChangeExample.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import SwiftUI
import AVFoundation

/// Example view showing how to handle audio device changes with InterruptibleChat
struct AudioDeviceChangeExample: View {
  @StateObject private var viewModel = AudioDeviceChangeViewModel()
  
  var body: some View {
    VStack(spacing: 20) {
      Text("Audio Device Change Demo")
        .font(.title)
        .padding()
      
      Group {
        Text("Status: \(viewModel.status)")
          .foregroundColor(statusColor)
        
        if let inputDevice = viewModel.currentInputDevice {
          Text("Input: \(inputDevice)")
            .font(.caption)
        }
        
        if let outputDevice = viewModel.currentOutputDevice {
          Text("Output: \(outputDevice)")
            .font(.caption)
        }
        
        if !viewModel.recognizedText.isEmpty {
          Text("Recognized: \"\(viewModel.recognizedText)\"")
            .italic()
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        
        if !viewModel.synthesizedText.isEmpty {
          Text("Synthesized: \"\(viewModel.synthesizedText)\"")
            .italic()
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
      }
      .animation(.easeInOut, value: viewModel.status)
      
      HStack(spacing: 15) {
        Button(action: viewModel.startListening) {
          Text("Start")
            .foregroundColor(.white)
            .padding()
            .background(Color.green)
            .cornerRadius(8)
        }
        .disabled(viewModel.isListening || viewModel.isRestarting)
        
        Button(action: viewModel.stopListening) {
          Text("Stop")
            .foregroundColor(.white)
            .padding()
            .background(Color.red)
            .cornerRadius(8)
        }
        .disabled(!viewModel.isListening || viewModel.isRestarting)
        
        Button(action: viewModel.testSynthesis) {
          Text("Test TTS")
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
        }
      }
      
      Button(action: viewModel.refreshDeviceInfo) {
        Text("Refresh Device Info")
          .foregroundColor(.white)
          .padding()
          .background(Color.orange)
          .cornerRadius(8)
      }
      
      Spacer()
    }
    .padding()
    .onAppear {
      viewModel.refreshDeviceInfo()
    }
  }
  
  private var statusColor: Color {
    switch viewModel.status {
    case "Listening":
      return .green
    case "Speaking":
      return .blue
    case "Error":
      return .red
    case let status where status.contains("Restarting"):
      return .orange
    default:
      return .primary
    }
  }
}

@MainActor
class AudioDeviceChangeViewModel: ObservableObject {
  @Published var status = "Ready"
  @Published var recognizedText = ""
  @Published var synthesizedText = ""
  @Published var isListening = false
  @Published var currentInputDevice: String?
  @Published var currentOutputDevice: String?
  @Published var isRestarting = false
  
  private var interruptibleChat: InterruptibleChat?
  private var deviceChangeObserver: NSObjectProtocol?
  private var lastKnownInputDevice: String?
  
  init() {
    setupAudioDeviceMonitoring()
  }
  
  deinit {
    if let observer = deviceChangeObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    #if os(macOS)
    AudioDeviceMonitor.stopMonitoring()
    #endif
  }
  
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
  
  #if os(macOS)
  private func handleMacOSAudioDeviceChange() {
    print("[AudioDeviceChangeViewModel] macOS audio device changed")
    
    let currentInputDevice = AudioDeviceMonitor.getCurrentInputDevice()
    if currentInputDevice != lastKnownInputDevice {
      print("[AudioDeviceChangeViewModel] Input device changed from '\(lastKnownInputDevice ?? "nil")' to '\(currentInputDevice ?? "nil")'")
      lastKnownInputDevice = currentInputDevice
      
      // If we're currently listening, restart the recognition to use the new device
      if isListening {
        print("[AudioDeviceChangeViewModel] Restarting recognition due to input device change")
        restartRecognition()
      }
    }
    
    // Refresh device info in UI
    refreshDeviceInfo()
  }
  #endif
  
  private func handleAudioRouteChange(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
      return
    }
    
    print("[AudioDeviceChangeViewModel] Audio route changed: \(reason)")
    
    // Check if input device changed
    let currentInputDevice = AudioDeviceMonitor.getCurrentInputDevice()
    if currentInputDevice != lastKnownInputDevice {
      print("[AudioDeviceChangeViewModel] Input device changed from '\(lastKnownInputDevice ?? "nil")' to '\(currentInputDevice ?? "nil")'")
      lastKnownInputDevice = currentInputDevice
      
      // If we're currently listening, restart the recognition to use the new device
      if isListening {
        print("[AudioDeviceChangeViewModel] Restarting recognition due to input device change")
        restartRecognition()
      }
    }
    
    // Refresh device info in UI
    refreshDeviceInfo()
  }
  
  private func restartRecognition() {
    isRestarting = true
    status = "Restarting due to device change..."
    
    // Stop current recognition
    interruptibleChat?.stop()
    
    // Small delay to ensure clean stop
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
      // Start again with new device
      self?.isRestarting = false
      self?.startListening()
    }
  }
  
  func startListening() {
    print("[AudioDeviceChangeViewModel] Starting listening...")
    
    // Configure audio session for better device change handling
    configureAudioSession()
    
    // Create a new InterruptibleChat instance
    interruptibleChat = InterruptibleChat(
      inputType: .microphone,
      locale: .current,
      activateSSML: false
    )
    
    // Update last known input device
    lastKnownInputDevice = AudioDeviceMonitor.getCurrentInputDevice()
    
    // Refresh device info to show current devices
    refreshDeviceInfo()
    
    interruptibleChat?.start(completion: { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success(let completion):
          if completion.isFinal && !completion.text.isEmpty {
            self?.recognizedText = completion.text
            self?.status = "Recognition complete"
            print("[AudioDeviceChangeViewModel] Final recognition: \(completion.text)")
          } else if !completion.isFinal {
            self?.recognizedText = completion.text
            print("[AudioDeviceChangeViewModel] Partial recognition: \(completion.text)")
          }
        case .failure(let error):
          self?.status = "Error"
          self?.isListening = false
          print("[AudioDeviceChangeViewModel] Recognition error: \(error.localizedDescription)")
        }
      }
    }, event: { [weak self] event in
      DispatchQueue.main.async {
        switch event {
        case .startedListening:
          self?.status = "Listening"
          self?.isListening = true
          print("[AudioDeviceChangeViewModel] Started listening")
        case .stoppedListening:
          self?.status = "Stopped listening"
          self?.isListening = false
          print("[AudioDeviceChangeViewModel] Stopped listening")
        case .startedSpeaking:
          self?.status = "Speaking"
          print("[AudioDeviceChangeViewModel] Started speaking")
        case .stoppedSpeaking:
          self?.status = "Stopped speaking"
          print("[AudioDeviceChangeViewModel] Stopped speaking")
        case .detectedSpeaking:
          self?.status = "User detected speaking"
          print("[AudioDeviceChangeViewModel] Detected user speaking")
        case .synthesizingRange(let range):
          print("[AudioDeviceChangeViewModel] Synthesizing range: \(range)")
        }
      }
    })
  }
  
  private func configureAudioSession() {
    #if !os(macOS)
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
      try audioSession.setActive(true)
      print("[AudioDeviceChangeViewModel] Audio session configured")
    } catch {
      print("[AudioDeviceChangeViewModel] Failed to configure audio session: \(error.localizedDescription)")
    }
    #endif
  }
  
  func stopListening() {
    print("[AudioDeviceChangeViewModel] Stopping listening...")
    interruptibleChat?.stop()
    isListening = false
    status = "Ready"
  }
  
  func testSynthesis() {
    print("[AudioDeviceChangeViewModel] Testing synthesis...")
    let testText = "This is a test of text-to-speech synthesis. Device changes should not interrupt this."
    synthesizedText = testText
    
    interruptibleChat?.synthesize(text: testText, isFinal: true)
  }
  
  func refreshDeviceInfo() {
    print("[AudioDeviceChangeViewModel] Refreshing device info...")
    currentInputDevice = AudioDeviceMonitor.getCurrentInputDevice()
    currentOutputDevice = AudioDeviceMonitor.getCurrentOutputDevice()
    
    // Print detailed device information to console
    AudioDeviceMonitor.printCurrentAudioDevices()
  }
}

#Preview {
  AudioDeviceChangeExample()
}
