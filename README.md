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

## Mermaid sample

```mermaid
  graph TD;
      A-->B;
      A-->C;
      B-->D;
      C-->D;
```
