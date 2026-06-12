# Refactoring Plan for bl-speech-recognizer

## Overview

This document outlines the phased refactoring approach for the bl-speech-recognizer project. Each phase is designed to be self-contained, verifiable, and buildable on its own. The goal is to transform the experimental codebase into a maintainable, testable library.

**Branch Strategy**: Create a long-lived `refactor/main` branch. Each phase gets its own sub-branch (`refactor/phase-1`, `refactor/phase-2`, etc.) merged into `refactor/main` upon completion.

---

## Phase 1: Establish Guardrails

**Goal**: Add tooling and CI so every subsequent change is verifiable.

**Risk**: Low
**Estimated Effort**: 1-2 hours
**Dependencies**: None

### Tasks

1. **Add SwiftFormat configuration**
   - Create `.swiftformat` at repository root
   - Use sensible defaults (4-space indentation, no trailing commas, etc.)
   - Run `swiftformat .` once to normalize existing files

2. **Add GitHub Actions CI**
   - Create `.github/workflows/ci.yml`
   - Jobs: `swift build` (macOS), `swift test` (macOS)
   - Use `macos-latest` runner

3. **Fix .gitignore and .build/ tracking**
   - `.build/` is already in `.gitignore` but tracked in git
   - Run `git rm -r --cached .build/` and commit
   - Verify no .build/ files remain tracked

4. **Add CONTRIBUTING.md template**
   - Expand from the current 3-line version
   - Include: build instructions, test instructions, PR checklist

### Verification

- [ ] `swift build` passes on macOS
- [ ] `swift test` passes on macOS
- [ ] CI workflow runs successfully on PR
- [ ] No `.build/` files in git index
- [ ] All files formatted consistently

### Files to Create
- `.swiftformat`
- `.github/workflows/ci.yml`
- `.github/pull_request_template.md`

### Files to Modify
- `.gitignore` (ensure `.build/` is present)
- `CONTRIBUTING.md`

---

## Phase 2: Kill Dead Code and Obvious Typos

**Goal**: Remove unused files and fix naming errors that will propagate if left.

**Risk**: Low
**Estimated Effort**: 30 minutes
**Dependencies**: Phase 1 (CI must be green first)

### Tasks

1. **Delete dead files**
   - `Sources/bl-speech-recognizer/bl_speech_recognizer.swift` (empty)
   - `Sources/bl-speech-recognizer/Utils/BLResponseSSMLStringBuffer.swift` (unused)

2. **Fix typo in event enum**
   - Rename `InterrumpibleChatEvent` to `InterruptibleChatEvent`
   - Add backward-compatible typealias: `public typealias InterrumpibleChatEvent = InterruptibleChatEvent`
   - Update all references in `InterruptibleChat.swift`, `InterruptibleChatWithAnalyzer.swift`, and example app

3. **Fix typo in error enum**
   - Rename `auidoPropertiesError` to `audioPropertiesError` in `SpeechRecognizerError.swift`
   - Add backward-compatible case: `case auidoPropertiesError(String) = audioPropertiesError(String)` if possible, or just add a deprecated alias

4. **Remove commented-out code**
   - Search for `//` blocks that are clearly disabled logic (not documentation)
   - Examples in `BLSpeechRecognizer.swift`, `InterruptibleChat.swift`, `BLSpeechSynthesizer.swift`

### Verification

- [ ] `swift build` passes
- [ ] `swift test` passes
- [ ] Example app `BLChat` compiles in Xcode
- [ ] No references to deleted files in `Package.swift` or elsewhere
- [ ] Backward compatibility aliases work (if exposed publicly)

### Files to Delete
- `Sources/bl-speech-recognizer/bl_speech_recognizer.swift`
- `Sources/bl-speech-recognizer/Utils/BLResponseSSMLStringBuffer.swift`

### Files to Modify
- `Sources/bl-speech-recognizer/InterruptibleChat.swift` (event enum references)
- `Sources/bl-speech-recognizer/InterruptibleChatWithAnalyzer.swift` (event enum references)
- `Sources/bl-speech-recognizer/Models/SpeechRecognizerError.swift` (typo fix)
- `examples/BLChat/Screens/Interruptible/InterruptibleChatViewModel.swift` (event enum references)
- Various files with commented-out code blocks

---

## Phase 3: Isolate iOS 26+ APIs

**Goal**: Separate the legacy `SFSpeechRecognizer`-based code from the new `SpeechAnalyzer`-based code to avoid confusion.

**Risk**: Medium
**Estimated Effort**: 2-3 hours
**Dependencies**: Phase 2

### Tasks

1. **Create directory structure**
   ```
   Sources/bl-speech-recognizer/
   ├── Legacy/
   │   ├── ContinuousSpeechRecognizer.swift
   │   ├── CommandSpeechRecognizer.swift
   │   ├── InterruptibleChat.swift
   │   └── AudioDeviceMonitor.swift
   ├── Modern/
   │   ├── InterruptibleChatWithAnalyzer.swift
   │   └── VoiceChatbotRecognizer.swift
   ├── Inputs/
   ├── Utils/
   └── Models/
   ```

2. **Move files to new locations**
   - Move legacy recognizers to `Legacy/`
   - Move modern recognizers to `Modern/`
   - Keep shared infrastructure (`Inputs/`, `Utils/`, `Models/`) in place

3. **Update access levels and imports**
   - Ensure `public` access is preserved for all public APIs
   - No import changes needed within the same module, but verify example app still works

4. **Add conditional compilation clarity**
   - Ensure `VoiceChatbotRecognizer.swift` and `InterruptibleChatWithAnalyzer.swift` have clear `@available(iOS 26.0, macOS 26.0, *)` annotations
   - Consider adding `#if available(iOS 26, *)` blocks where appropriate

### Verification

- [ ] `swift build` passes
- [ ] `swift test` passes
- [ ] Example app `BLChat` compiles and runs in Xcode
- [ ] Public API surface is unchanged (no breaking changes)
- [ ] All iOS 26+ APIs are clearly marked and isolated

### Files to Create
- Directory structure only

### Files to Move
- `ContinuousSpeechRecognizer.swift` → `Legacy/`
- `CommandSpeechRecognizer.swift` → `Legacy/`
- `InterruptibleChat.swift` → `Legacy/`
- `AudioDeviceMonitor.swift` → `Legacy/` (or keep in root if shared)
- `InterruptibleChatWithAnalyzer.swift` → `Modern/`
- `VoiceChatbotRecognizer.swift` → `Modern/`

---

## Phase 4: Extract Protocols for Testability

**Goal**: Make the library mockable by exposing protocols and hiding concrete implementations.

**Risk**: Medium
**Estimated Effort**: 4-6 hours
**Dependencies**: Phase 3

### Tasks

1. **Promote internal protocols to public**
   - `BLSpeechRecognizerDelegate` → `public protocol`
   - `SpeechSynthesizerProtocol` → `public protocol`
   - `BLSpeechRecognizerInput` → `public protocol` (or merge with delegate)

2. **Create abstract protocols for Apple types**
   - `SpeechRecognizerProtocol` — abstract `SFSpeechRecognizer`
   - `AudioSessionProtocol` — abstract `AVAudioSession`
   - These allow injecting mocks in tests

3. **Refactor concrete classes to depend on protocols**
   - `BLSpeechRecognizer` should accept `SpeechRecognizerProtocol` in init
   - `MicrophoneInputSource` should accept `AudioSessionProtocol`
   - Default to real Apple types when no mock is injected

4. **Create mock implementations**
   - `MockSpeechRecognizer` — returns predefined results
   - `MockAudioSession` — simulates permissions and device states
   - Place in `Tests/bl-speech-recognizerTests/Mocks/`

5. **Write unit tests for public APIs**
   - `ContinuousSpeechRecognizerTests` — test start/stop, delegate callbacks
   - `CommandSpeechRecognizerTests` — test timer-based stopping
   - `InterruptibleChatTests` — test synthesize + interrupt flow
   - All tests should be fast (< 100ms) and deterministic

### Verification

- [ ] `swift build` passes
- [ ] `swift test` passes (new tests included)
- [ ] All public APIs have protocol abstractions
- [ ] Mock tests run in < 1 second total
- [ ] No test depends on real audio or network

### Files to Create
- `Sources/bl-speech-recognizer/Protocols/SpeechRecognizerProtocol.swift`
- `Sources/bl-speech-recognizer/Protocols/AudioSessionProtocol.swift`
- `Tests/bl-speech-recognizerTests/Mocks/MockSpeechRecognizer.swift`
- `Tests/bl-speech-recognizerTests/Mocks/MockAudioSession.swift`
- `Tests/bl-speech-recognizerTests/CommandSpeechRecognizerTests.swift`
- `Tests/bl-speech-recognizerTests/InterruptibleChatTests.swift`

### Files to Modify
- `Sources/bl-speech-recognizer/Utils/BLSpeechRecognizer.swift` (protocol conformance)
- `Sources/bl-speech-recognizer/Utils/BLSpeechSynthesizer.swift` (protocol conformance)
- `Sources/bl-speech-recognizer/Inputs/MicrophoneInputSource.swift` (protocol injection)
- `Sources/bl-speech-recognizer/ContinuousSpeechRecognizer.swift` (protocol usage)
- `Sources/bl-speech-recognizer/CommandSpeechRecognizer.swift` (protocol usage)
- `Sources/bl-speech-recognizer/InterruptibleChat.swift` (protocol usage)

---

## Phase 5: Fix Concurrency Safety

**Goal**: Replace `@unchecked Sendable` with proper Swift Concurrency.

**Risk**: High
**Estimated Effort**: 4-8 hours
**Dependencies**: Phase 4

### Tasks

1. **Enable strict concurrency checking**
   - Add to `Package.swift` swiftSettings: `-strict-concurrency=complete`
   - Build and catalog all warnings/errors

2. **Audit each `@unchecked Sendable` class**
   - `CommandSpeechRecognizer` — likely needs `actor` or `@MainActor` class
   - `InterruptibleChat` — complex state, needs careful isolation
   - `BLSpeechRecognizer` — holds `SFSpeechRecognizer` (not Sendable)

3. **Introduce Actor types where appropriate**
   - `AudioSessionManager` could be an actor
   - `BLSpeechRecognizer` state (timer, task) could be isolated to an actor
   - Keep UI-facing APIs on `@MainActor`

4. **Remove `@unchecked Sendable` annotations**
   - Replace with `Sendable` conformance only when truly safe
   - Use `@preconcurrency` for Apple API boundaries if needed

5. **Fix delegate patterns for concurrency**
   - `BLSpeechRecognizerDelegate` methods should be `async` or `@MainActor` if they update UI
   - Ensure delegate callbacks happen on the right executor

### Verification

- [ ] `swift build` passes with `-strict-concurrency=complete`
- [ ] Zero concurrency warnings
- [ ] `swift test` passes
- [ ] Example app runs without crashes
- [ ] No race conditions in `ThreadSanitizer` (if run on device)

### Files to Modify
- `Package.swift` (add swiftSettings)
- `Sources/bl-speech-recognizer/CommandSpeechRecognizer.swift`
- `Sources/bl-speech-recognizer/InterruptibleChat.swift`
- `Sources/bl-speech-recognizer/InterruptibleChatWithAnalyzer.swift`
- `Sources/bl-speech-recognizer/Utils/BLSpeechRecognizer.swift`
- `Sources/bl-speech-recognizer/Utils/BLSpeechSynthesizer.swift`
- `Sources/bl-speech-recognizer/Utils/AudioSessionManager.swift`
- `Sources/bl-speech-recognizer/Inputs/MicrophoneInputSource.swift`

---

## Phase 6: Add Real Tests

**Goal**: Replace stubs with meaningful, fast tests.

**Risk**: Medium
**Estimated Effort**: 3-4 hours
**Dependencies**: Phase 4 (mocks), Phase 5 (concurrency-safe code)

### Tasks

1. **Remove or gate flaky tests**
   - `ContinuousSpeechRecognizerTests.testStartRecognition()` — currently uses real audio and 5-second sleep
   - Either: delete it, or gate behind `PROCESS_REAL_AUDIO` environment variable
   - Keep it as an integration test, not a unit test

2. **Write comprehensive unit tests**
   - `ContinuousSpeechRecognizer` — mock input, verify delegate callbacks
   - `CommandSpeechRecognizer` — mock input, verify timer stops after inactivity
   - `InterruptibleChat` — mock synthesizer + recognizer, verify interrupt flow
   - `InputSourceFactory` — verify correct type creation
   - `AudioSessionManager` — mock AVAudioSession, verify configuration options

3. **Add test coverage reporting**
   - `swift test --enable-code-coverage`
   - Add coverage badge to README

4. **Document test strategy**
   - Unit tests: fast, mocked, run in CI
   - Integration tests: require real device, run manually
   - UI tests: optional, for example app only

### Verification

- [ ] `swift test` runs in < 10 seconds
- [ ] All tests pass (unit tests only in CI)
- [ ] Code coverage > 70% for core logic
- [ ] No test sleeps or blocks for real I/O

### Files to Create
- `Tests/bl-speech-recognizerTests/Mocks/` (if not created in Phase 4)
- `Tests/bl-speech-recognizerTests/CommandSpeechRecognizerTests.swift`
- `Tests/bl-speech-recognizerTests/InterruptibleChatTests.swift`
- `Tests/bl-speech-recognizerTests/InputSourceTests.swift`
- `Tests/bl-speech-recognizerTests/AudioSessionManagerTests.swift`

### Files to Modify
- `Tests/bl-speech-recognizerTests/ContinuousSpeechRecognizerTests.swift` (remove or gate flaky test)
- `Tests/bl-speech-recognizerTests/bl_speech_recognizerTests.swift` (remove empty stub)
- `Package.swift` (add test target settings if needed)

---

## Post-Refactoring Checklist

After all 6 phases are complete:

- [ ] `README.md` is updated with current architecture
- [ ] `CHANGELOG.md` documents all breaking changes
- [ ] DocC archive is regenerated (`swift build --target DocC` or Xcode build)
- [ ] Version bumped to `1.0.0` (if breaking changes were made)
- [ ] All `@available` annotations are correct for minimum deployment targets
- [ ] Example app `BLChat` is verified on a real device

---

## Appendix: Using OpenCode for This Plan

### Recommended Skill Usage

| Phase | Command | Skills |
|-------|---------|--------|
| 1 | `task(category="quick")` | `[]` |
| 2 | `task(category="quick")` | `[]` |
| 3 | `task(category="unspecified-high")` | `[]` |
| 4 | `task(category="deep")` | `[]` |
| 5 | `task(category="ultrabrain")` | `[]` |
| 6 | `task(category="deep")` | `[]` |
| Review | `skill(name="review-work")` | `review-work` |

### Parallelization Opportunities

- Phases 1 and 2 can be combined into a single task since they are both low-risk
- Phase 4 (protocol extraction) and Phase 6 (tests) can be worked on in parallel once mocks are defined
- Phase 5 (concurrency) should be done in isolation due to high risk

### Continuation Strategy

Use `schedule_job` to set up recurring checks:
- Daily CI status check on `refactor/main`
- Weekly `swiftformat` linting

Or use the `ralph-loop` command to keep an agent working on the next phase until completion.

---

## Risk Mitigation

- **Breaking Changes**: If any phase introduces a breaking change, add `@available(*, deprecated)` shims
- **Device Testing**: Concurrency and audio session changes MUST be tested on a real device. The simulator does not fully simulate AVAudioSession.
- **Bluetooth**: AudioSessionManager changes need manual testing with Bluetooth headsets, AirPods, and wired headphones.
- **CI Limitations**: GitHub Actions macOS runners cannot test microphone or speech recognition. Mark those as manual-only.

---

*Plan created: 2026-06-12*
*Next review: After Phase 2 completion*
