//
//  AudioDeviceMonitor.swift
//  bl-speech-recognizer
//
//  Created by Daniel Vela on 31/12/24.
//

import Foundation
import AVFoundation
#if os(macOS)
import CoreAudio
#endif

/// Utility class to monitor and provide information about audio device changes
public class AudioDeviceMonitor {
    
    /// Gets the current input device name
    public static func getCurrentInputDevice() -> String? {
        #if os(macOS)
        return getCurrentInputDeviceMacOS()
        #else
        return getCurrentInputDeviceIOS()
        #endif
    }
    
    /// Gets the current output device name
    public static func getCurrentOutputDevice() -> String? {
        #if os(macOS)
        return getCurrentOutputDeviceMacOS()
        #else
        return getCurrentOutputDeviceIOS()
        #endif
    }
    
    #if os(macOS)
    /// macOS: Get current input device using Core Audio
    private static func getCurrentInputDeviceMacOS() -> String? {
        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        
        guard status == noErr else {
            print("[AudioDeviceMonitor] Failed to get input device ID: \(status)")
            return nil
        }
        
        return getDeviceName(deviceID: deviceID)
    }
    
    /// macOS: Get current output device using Core Audio
    private static func getCurrentOutputDeviceMacOS() -> String? {
        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        
        guard status == noErr else {
            print("[AudioDeviceMonitor] Failed to get output device ID: \(status)")
            return nil
        }
        
        return getDeviceName(deviceID: deviceID)
    }
    
    /// macOS: Get device name from device ID
    private static func getDeviceName(deviceID: AudioDeviceID) -> String? {
        var size: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Get the size first
        var status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size)
        guard status == noErr else {
            print("[AudioDeviceMonitor] Failed to get device name size: \(status)")
            return nil
        }
        
        // Get the actual name
        var deviceName: CFString?
        status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &deviceName)
        guard status == noErr, let name = deviceName else {
            print("[AudioDeviceMonitor] Failed to get device name: \(status)")
            return nil
        }
        
        return name as String
    }
    
    #else
    /// iOS: Get current input device using AVAudioSession
    private static func getCurrentInputDeviceIOS() -> String? {
        let session = AVAudioSession.sharedInstance()
        return session.currentRoute.inputs.first?.portName
    }
    
    /// iOS: Get current output device using AVAudioSession
    private static func getCurrentOutputDeviceIOS() -> String? {
        let session = AVAudioSession.sharedInstance()
        return session.currentRoute.outputs.first?.portName
    }
    #endif
    
    /// Prints current audio device information for debugging
    public static func printCurrentAudioDevices() {
        let inputDevice = getCurrentInputDevice() ?? "Unknown"
        let outputDevice = getCurrentOutputDevice() ?? "Unknown"
        
        print("[AudioDeviceMonitor] Current input device: \(inputDevice)")
        print("[AudioDeviceMonitor] Current output device: \(outputDevice)")
        
        #if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        print("[AudioDeviceMonitor] Available inputs:")
        for input in session.availableInputs ?? [] {
            print("  - \(input.portName) (\(input.portType.rawValue))")
        }
        
        print("[AudioDeviceMonitor] Current route:")
        for input in session.currentRoute.inputs {
            print("  Input: \(input.portName) (\(input.portType.rawValue))")
        }
        for output in session.currentRoute.outputs {
            print("  Output: \(output.portName) (\(output.portType.rawValue))")
        }
        #endif
    }
}