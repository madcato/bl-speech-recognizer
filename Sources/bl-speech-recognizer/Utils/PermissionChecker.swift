//
//  PermissionChecker.swift
//  bl-speech-recognizer
//
//  Cross-platform permission checking utility for speech recognition and audio permissions
//

import Foundation
import Speech

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Cross-platform utility for checking audio and speech recognition permissions
public class PermissionChecker {
    
    // MARK: - Microphone Permission
    
    /// Checks if microphone permission is granted on both iOS and macOS
    public static func checkMicrophonePermission() -> Bool {
        #if os(iOS)
        return AVAudioSession.sharedInstance().recordPermission == .granted
        #elseif os(macOS)
        // On macOS, check if we can access the audio input device
        return checkMacOSMicrophonePermission()
        #else
        return false
        #endif
    }
    
    /// Requests microphone permission on both iOS and macOS
    public static func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        #if os(iOS)
      if #available(iOS 17.0, *) {
        AVAudioApplication.requestRecordPermission { granted in
          DispatchQueue.main.async {
            completion(granted)
          }
        }
      } else {
        // Fallback on earlier versions
      }
        #elseif os(macOS)
        requestMacOSMicrophonePermission(completion: completion)
        #else
        completion(false)
        #endif
    }
    
    // MARK: - Speech Recognition Permission
    
    /// Checks if speech recognition permission is granted on both platforms
    public static func checkSpeechRecognitionPermission() -> Bool {
        return SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    /// Requests speech recognition permission
    public static func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    // MARK: - Voice Availability
    
    /// Checks if text-to-speech voices are available
    public static func checkVoiceAvailability() -> Bool {
        #if canImport(AVFoundation)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        return !voices.isEmpty
        #else
        return false
        #endif
    }
    
    /// Gets available voices for text-to-speech
    public static func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        #if canImport(AVFoundation)
        return AVSpeechSynthesisVoice.speechVoices()
        #else
        return []
        #endif
    }
    
    // MARK: - macOS Specific Implementations
    
    #if os(macOS)
    private static func checkMacOSMicrophonePermission() -> Bool {
        // On macOS 10.14+, we need to check for microphone access
        if #available(macOS 10.14, *) {
            let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
            return authorizationStatus == .authorized
        } else {
            // On older macOS versions, microphone access is assumed to be available
            return true
        }
    }
    
    private static func requestMacOSMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if #available(macOS 10.14, *) {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            // On older macOS versions, assume permission is granted
            completion(true)
        }
    }
    #endif
    
    // MARK: - Permission Status Enum
    
    public enum PermissionStatus {
        case granted
        case denied
        case notDetermined
        case restricted
        
        public var isGranted: Bool {
            return self == .granted
        }
    }
    
    // MARK: - Comprehensive Permission Check
    
    /// Checks all permissions needed for speech recognition functionality
    public static func checkAllPermissions() -> [String: PermissionStatus] {
        var permissions: [String: PermissionStatus] = [:]
        
        // Microphone permission
        let micPermission = checkMicrophonePermission()
        permissions["microphone"] = micPermission ? .granted : .denied
        
        // Speech recognition permission
        let speechAuthStatus = SFSpeechRecognizer.authorizationStatus()
        switch speechAuthStatus {
        case .authorized:
            permissions["speechRecognition"] = .granted
        case .denied:
            permissions["speechRecognition"] = .denied
        case .restricted:
            permissions["speechRecognition"] = .restricted
        case .notDetermined:
            permissions["speechRecognition"] = .notDetermined
        @unknown default:
            permissions["speechRecognition"] = .notDetermined
        }
        
        // Voice availability
        let voiceAvailable = checkVoiceAvailability()
        permissions["voiceAvailability"] = voiceAvailable ? .granted : .denied
        
        return permissions
    }
    
    /// Checks if all required permissions are granted
    public static func areAllPermissionsGranted() -> Bool {
        let permissions = checkAllPermissions()
        return permissions.values.allSatisfy { $0.isGranted }
    }
}

// MARK: - Extensions

extension PermissionChecker {
    
    /// Request all necessary permissions sequentially
    public static func requestAllPermissions(completion: @escaping ([String: Bool]) -> Void) {
        var results: [String: Bool] = [:]
        
        // Request microphone permission first
        requestMicrophonePermission { micGranted in
            results["microphone"] = micGranted
            
            // Then request speech recognition
            requestSpeechRecognitionPermission { speechGranted in
                results["speechRecognition"] = speechGranted
                
                // Voice availability doesn't require permission request
                results["voiceAvailability"] = checkVoiceAvailability()
                
                completion(results)
            }
        }
    }
}
