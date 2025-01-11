# bl-speech-recognizer

Some implemented use cases for SFSpeechRecognizer. 

## IMPORTANT

From [Apple](https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition):

![Apple important for speech recognition](doc/apple-important-speech-recognition.png)

Add [NSSpeechRecognitionUsageDescription](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSSpeechRecognitionUsageDescription) to your project _.plist_ file. This key is required if your app uses APIs that send user data to Apple’s speech recognition servers.

## Apple documentation

- Sample code: [Recognizing speech in live audio](https://developer.apple.com/documentation/speech/recognizing-speech-in-live-audio)
- Framework:[Speech](https://developer.apple.com/documentation/speech)
- Article: [Asking Permission to Use Speech Recognition](https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition)

## Sample usage

See [Example app](./examples) to learn how to use the library.

### Continouos speech recognition

```swift
import bl_speech_recognizer

class YourClassViewModel: ObservableObject { 
    // ... your properties
    private var speechRecognizer = ContinuousSpeechRecognizer()
    
    @MainActor
    func startRecording() {
        isRecording = true
    
        speechRecognizer.start(inputType: .microphone, locale: .current) { result in
            switch result {
            case .success(let text):
                self.recognizedText = text
            case .failure(let error):
                self.showError(error.localizedDescription)
            }
        }
    }

    @MainActor
    func stopRecording() {
        isRecording = false
        speechRecognizer.stop()
    }
}
```

You need to stop recognition by calling `stop()` on the recognizer.

### Command speech recognition

```swift
import bl_speech_recognizer

class YourClassViewModel: ObservableObject { 
    // ... your properties

    private var speechRecognizer = CommandSpeechRecognizer()

    @MainActor
    func startRecording() {
        isRecording = true
        speechRecognizer.start(inputType: .microphone, locale: .current) { result in
            switch result {
            case .success(let text):
                self.recognizedText = text
                self.isRecording = false
            case .failure(let error):
                self.showError(error.localizedDescription)
            }
        }
    }
}
```

You don't need to stop recognition, because the **CommandSpeechRecognizer** will do it. But you can add it to allow user to stop it.

## Use cases sequence diagrams

### Continuous recognition

```mermaid
sequenceDiagram
    App->>bl-speech-recognizer: start()
    actor User
    User-->>bl-speech-recognizer: "Hello"
    bl-speech-recognizer->>App: recognized("Hello")
    User-->>bl-speech-recognizer: "how"
    bl-speech-recognizer->>App: recognized("Hello how")
    User-->>bl-speech-recognizer: "are"
    bl-speech-recognizer->>App: recognized("Hello how are")
    User-->>bl-speech-recognizer: "you"
    bl-speech-recognizer->>App: recognized("Hello how are you")
    App->>bl-speech-recognizer: stop()
```

### Command recognition

```mermaid
sequenceDiagram
    App->>bl-speech-recognizer: start()
    actor User
    User-->>bl-speech-recognizer: "Delete"
    User-->>bl-speech-recognizer: "all"
    User-->>bl-speech-recognizer: "files"
    User-->>bl-speech-recognizer: (One second without speech)
    bl-speech-recognizer->>App: recognized("Delete all files")
    bl-speech-recognizer->>bl-speech-recognizer: stop()
```
