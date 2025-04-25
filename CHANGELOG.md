# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2025-04-25

### Added

- Echo cancelation using AEC (iOS 16+)

## [0.5.6] - 2025-04-19

### Added

- Configure rate and pitch modifiers for speech synthesizer.
- Detect when user is speaking, before the text is recognized.
- Background modes for BLChat example.

### Changed

- Speech recognizing is performed in a background thread to avoid blocking the main thread.
- Synthesyzing is interrumpted when .detectedSpeaking event is launched.

### Fixed

- Code refactoring to improve overall running performance.

## [0.5.5] - 2025-03-11

### Added

- Set `requiresOnDeviceRecognition = true`
- Voice **pitch** and **rate** modifiers for the speech synthesizer.

### Fixed

- Refactored stop behavior for microphone input.

### Updated

- `InterrumpibleChat` now only calls completion handler once, whe the user has finished speaking.

## [0.5.4] - 2025-02-25

### Added
- Optional speech syntheziser pitch and rate modifiers

## [0.5.3] - 2025-02-17

### Fixed

- `internalSpeak` was being calling recursively at synthesizing finish.

## [0.5.2] - 2025-02-11

### Fixed

- Fix restart of synthesizer.

## [0.5.1] - 2025-02-11

### Fixed
- Restart of interruptibleChat

## [0.5.0] - 2025-02-11

### Changed
- InterrumpibleChat start/stop events 
- CommandSpeechRecornigzer start/stop events
- ContinuousSpeechRecognizer start/stop events
  
## [0.4.1] - 2025-02-11

### Fixed
- Error handler doesn't notify when the user permission to use speech recognizer was denied.

## [0.4.0] - 2025-02-11
### Added
- Method to list all available voices.

### Changed
- Allow (optional) to specify a synthesizer voice.

### Fixed
- Interrumpible chat sequence Mermaid.

## [0.3.2] - 2025-01-20
### Fixed
- Fix misspelling Interruptible.
- Fix Interruptible chat model to always synthetize.
- Fix restart the recognition when **isFinal** is true.
- Fix synthesizer to take into account the puntuation of the text.
- Fix synthesizer to flush all the remaining text whe **isFinal** es true.

## [0.3.1] - 2025-01-18

### Fixed
- Fix completion result struct.

## [0.3.0] - 2025-01-12

### Added
- Chat functionality with interruptions when user speaks.

### Changed
- Example app sample for chat functionality.

## [0.2.0] - 2025-01-11

### Added
- Command speech recognition functionality.
- Test case for command recognition.

### Changed
- Example app sample for command recognition.

## [0.1.0] - 2025-01-11

### Added
- Continuous speech recognition functionality.
- Test case for continuous recognition.
- Example app demonstrating the use of the recognizer.

## [Unreleased]

### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

