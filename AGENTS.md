# AGENTS.md

## Project Overview

This is an **investigation/research project** for iOS/macOS voice assistant helper classes. It wraps `SFSpeechRecognizer` and `AVSpeechSynthesizer` with higher-level APIs. The codebase is **experimental and needs refactoring** — do not assume production-grade patterns.

## Build & Test

- **Package Manager**: Swift Package Manager (SPM), `swift-tools-version: 5.5`
- **Platforms**: iOS 13+, macOS 10.15+ (some newer APIs gated behind `iOS 26.0+` / `macOS 26.0+`)
- **Build**: `swift build` (macOS only; iOS requires Xcode)
- **Test**: `swift test` — but tests are **minimal and mostly stubs**:
  - `bl_speech_recognizerTests.swift` uses the new `Testing` framework (not XCTest)
  - `ContinuousSpeechRecognizerTests.swift` uses XCTest and references audio files (`hello.m4a`, `hola.m4a`) in `Bundle.module`
- **Example App**: `examples/BLChat/BLChat.xcodeproj` — a SwiftUI demo app with tabs for Continuous, Command, and Interruptible recognition modes. Must be built via Xcode (not SPM).
- **DocC**: Pre-built archive exists at `doc/bl-speech-recognizer.doccarchive/`

## Architecture

### Public API Surface
The library exposes three main recognizers:
- `ContinuousSpeechRecognizer` — long-form dictation, streams results continuously
- `CommandSpeechRecognizer` — short command recognition, stops after inactivity
- `InterruptibleChat` — bidirectional chat: listens while synthesizing speech; user speech interrupts TTS
- `InterruptibleChatWithAnalyzer` — iOS 26+ only; uses `SpeechAnalyzer` / `SpeechTranscriber` / `SpeechDetector` APIs

### Internal Structure
- `BLSpeechRecognizer` — internal wrapper around `SFSpeechRecognizer`; handles permissions, tasks, and audio buffer plumbing
- `BLSpeechSynthesizer` — internal wrapper around `AVSpeechSynthesizer`; manages a text buffer and queued utterances
- `InputSource` / `InputSourceFactory` — abstraction over `.microphone`, `.audioFile(URL)`, `.customStream`
- `AudioSessionManager` — centralizes `AVAudioSession` configuration (playAndRecord + voiceChat mode, Bluetooth detection, echo cancellation)
- `VoiceChatbotRecognizer` — iOS 26+ implementation using `SpeechAnalyzer` instead of the legacy `SFSpeechRecognizer`

### Key Gotchas
- `AVSpeechSynthesizer.usesApplicationAudioSession = false` on iOS to avoid volume conflicts with voice chat mode
- Bluetooth detection is performed at setup time; if no Bluetooth, `.defaultToSpeaker` is added
- The `bl_speech_recognizer.swift` file at `Sources/bl-speech-recognizer/bl_speech_recognizer.swift` is **empty** (only a comment). Do not treat it as an entry point.

## Concurrency & Safety

- Multiple classes use `@unchecked Sendable` (e.g., `CommandSpeechRecognizer`, `InterruptibleChat`). This is **not guaranteed safe** — the author was suppressing warnings during experimentation.
- Many `start` / `stop` methods are marked `@MainActor`. When refactoring, prefer proper Swift Concurrency (`isolated` parameters, `Actor` types) over `@unchecked Sendable`.
- `BLSpeechRecognizerDelegate` and `BLSpeechSynthesizerDelegate` are `AnyObject` (class-only) protocols. Watch for retain cycles.

## Permissions & Entitlements

Apps using this library **must** add these keys to their `Info.plist`:
- `NSSpeechRecognitionUsageDescription` — required by Apple for any speech recognition
- `NSMicrophoneUsageDescription` — required for real-device microphone input (optional on Simulator)

## Testing Quirks

- Tests are incomplete. `ContinuousSpeechRecognizerTests` expects real audio recognition to return `"Hello how are you"` for `hello.m4a`. This is flaky and slow (5-second sleep + 10-second timeout).
- No mock infrastructure exists for `SFSpeechRecognizer` or `AVAudioSession`. Any serious refactoring should introduce protocol-based mocking first.
- The `Testing` framework test (`bl_speech_recognizerTests.swift`) is literally an empty stub.

## Refactoring Notes (High Priority)

1. **Remove dead code**: `bl_speech_recognizer.swift`, commented-out code blocks, unused SSML buffer paths
2. **Unify naming**: `InterrumpibleChatEvent` (note the typo) vs `InterruptibleChat` — fix or preserve consistently
3. **Separate iOS 26+ APIs**: `InterruptibleChatWithAnalyzer` and `VoiceChatbotRecognizer` use entirely new Apple APIs. Keep them in a dedicated subfolder or conditional compilation block to avoid confusion.
4. **Extract protocols**: Several internal protocols (`BLSpeechRecognizerDelegate`, `SpeechSynthesizerProtocol`) should be promoted to public if consumers need to inject mocks.
5. **Audio resource management**: `MicrophoneInputSource` creates `AVAudioEngine` and installs tap callbacks. Ensure `deinit` / `stop` always cleans up the engine and removes taps to avoid crashes.
6. **Error handling**: `SpeechRecognizerError` has a typo (`auidoPropertiesError`). Consider deprecating and renaming.
7. **Localization**: Some source comments and internal strings are in Spanish. Standardize to English for a public library.
8. **No CI/CD, no linter, no formatter**: Add `.github/workflows`, SwiftLint, or SwiftFormat as part of the refactor.

## Environment & Tooling

- **No SwiftLint / SwiftFormat** — no config files for linting or formatting.
- `.build/` is properly ignored in `.gitignore`.
- `.swiftpm/` is now ignored (was previously tracked with generated Xcode scheme files).
- The `.sisyphus` directory contains OpenCode session metadata; do not edit.

## Dependencies

- **Zero external SPM dependencies**. Only Apple frameworks: `Speech`, `AVFoundation`, `AVFAudio`, `AudioToolbox`, `CoreAudio` (macOS only).
- This keeps the package lightweight but also means you must handle all audio session edge cases manually.

## How to Verify Changes

1. `swift build` — must compile on macOS
2. `swift test` — runs the minimal test suite
3. For iOS behavior: open `examples/BLChat/BLChat.xcodeproj` in Xcode and run on a real device (Simulator lacks full microphone/speech recognition support)
4. Test Bluetooth + speaker routing scenarios manually — the `AudioSessionManager` logic is sensitive to hardware state

## File Map

```
Sources/bl-speech-recognizer/
  ├── ContinuousSpeechRecognizer.swift      # Public API: dictation
  ├── CommandSpeechRecognizer.swift           # Public API: short commands
  ├── InterruptibleChat.swift                 # Public API: chat + TTS
  ├── InterruptibleChatWithAnalyzer.swift     # Public API: iOS 26+ chat
  ├── AudioDeviceMonitor.swift                # Hardware change notifications
  ├── Inputs/
  │   ├── InputSource.swift                   # Protocol + factory
  │   ├── MicrophoneInputSource.swift         # Live audio input
  │   ├── AudioFileInput.swift                # File-based input
  │   └── CustomInputSource.swift             # Custom buffer input
  ├── Utils/
  │   ├── BLSpeechRecognizer.swift            # Internal SFSpeechRecognizer wrapper
  │   ├── BLSpeechSynthesizer.swift           # Internal AVSpeechSynthesizer wrapper
  │   ├── AudioSessionManager.swift           # AVAudioSession setup
  │   ├── VoiceChatbotRecognizer.swift         # iOS 26+ SpeechAnalyzer wrapper
  │   ├── BLStringBuffer.swift                # Text buffering helpers
  │   ├── BLResponseStringBuffer.swift          # SSML-aware buffer
  │   ├── BLResponseSSMLStringBuffer.swift      # (mostly unused)
  │   ├── BufferConverter.swift               # Audio buffer format conversion
  │   └── PermissionChecker.swift             # Speech / mic permission checks
  └── Models/
      ├── SpeechRecognitionResult.swift       # Result models
      └── SpeechRecognizerError.swift         # Error enum
```
