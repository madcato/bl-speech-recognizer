# Audio Device Change Handling in bl-speech-recognizer

## Problem Resolved

The `bl-speech-recognizer` library now properly handles audio device changes in real-time. Previously, when a user changed the audio source (for example, from internal speakers to AirPods), speech recognition and synthesis would stop working correctly.

## Implemented Solution

### 1. Automatic Device Change Detection

The `MicrophoneInputSource` class now includes:

- **macOS**: Uses Core Audio notifications to detect input and output device changes
- **iOS**: Uses `AVAudioSession` notifications to detect route changes and interruptions

### 2. Automatic Audio Engine Reinitialization

When a device change is detected:
1. The current `AVAudioEngine` is stopped in a controlled manner
2. Wait 0.5 seconds for the device change to complete
3. Reinitialize the audio engine with the new configuration
4. Recognition continues automatically

### 3. Device Monitoring

The new `AudioDeviceMonitor` class provides:
- Information about current input and output devices
- Debugging functions to print detailed audio information
- Cross-platform compatibility (macOS and iOS)

## Usage

### Basic Usage (No Changes)

The usage of `InterruptibleChat` remains the same:

```swift
let chat = InterruptibleChat(
    inputType: .microphone,
    locale: .current,
    activateSSML: false
)

chat.start(completion: { result in
    // Handle result
}, event: { event in
    // Handle events
})
```

### Device Monitoring

```swift
// Get current device information
let inputDevice = AudioDeviceMonitor.getCurrentInputDevice()
let outputDevice = AudioDeviceMonitor.getCurrentOutputDevice()

// Print detailed information for debugging
AudioDeviceMonitor.printCurrentAudioDevices()
```

### Complete Example

See `AudioDeviceChangeExample.swift` for a complete example with UI that demonstrates:
- Starting and stopping recognition
- Text-to-speech synthesis tests
- Real-time monitoring of device changes
- Current status visualization

## Supported Use Cases

### macOS
- ✅ Switch from Mac Mini internal speakers to AirPods
- ✅ Switch from AirPods Max to monitor speakers
- ✅ USB device connection/disconnection
- ✅ Bluetooth device switching

### iOS
- ✅ AirPods connection/disconnection
- ✅ Switching between speakers and headphones
- ✅ Phone call interruptions
- ✅ System audio route changes

## Debugging

### Informative Logs

The implementation includes detailed logs:

```
[MicrophoneInputSource] Audio device change detected
[MicrophoneInputSource] Restarting audio engine due to device change
[MicrophoneInputSource] Audio engine restarted successfully
[AudioDeviceMonitor] Current input device: AirPods Pro
[AudioDeviceMonitor] Current output device: AirPods Pro
```

### Check Audio Status

```swift
// In your ViewModel or controller
func checkAudioStatus() {
    AudioDeviceMonitor.printCurrentAudioDevices()
}
```

## Performance Considerations

- Audio engine reinitialization introduces minimal latency (~0.5 seconds)
- Device changes are detected immediately
- No performance impact when no device changes occur
- Implementation uses system notifications, not polling

## Error Handling

Errors related to device changes are reported through the delegate:

```swift
// In your BLSpeechRecognizerDelegate implementation
func speechRecognizer(error: any Error) {
    if let error = error as? SpeechRecognizerError,
       case .audioDeviceChangeError(let message) = error {
        print("Device change error: \(message)")
        // Handle specific error
    }
}
```

## Limitations

1. **Temporary latency**: There's a brief interruption (~0.5s) during device changes
2. **macOS Simulator**: Device changes cannot be fully simulated
3. **Incompatible devices**: Some very old audio devices may not be detected correctly

## Testing

To test the functionality:

1. Run the app on a physical device (not simulator)
2. Start speech recognition
3. Change the audio device (connect/disconnect AirPods, etc.)
4. Verify that recognition continues working
5. Check the logs in the console to confirm device change detection

The `AudioDeviceChangeExample` example provides a visual interface to facilitate testing.