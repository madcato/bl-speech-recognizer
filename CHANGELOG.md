# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Method to list all available voices.

### Changed
- Allow (optional) to specify a synthesizer voice.

### Deprecated
### Removed
### Fixed
- Interrumpible chat sequence Mermaid.

### Security

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
