# Contributing to bl-speech-recognizer

## Getting Started

1. Clone the repository
2. Ensure you have Xcode 14+ or Swift 5.5+ toolchain installed
3. Run `swift build` to verify compilation
4. Run `swift test` to run the test suite

## Pull Request Process

1. Create a new branch for your changes
2. Make your changes with clear, descriptive commit messages
3. Ensure all tests pass: `swift test`
4. Update documentation if needed (README.md, AGENTS.md, or DocC comments)
5. Submit a PR with a clear description of the changes

## Code Style

- Follow the existing code style in the repository
- Use 2-space indentation
- Keep lines under 120 characters
- Add meaningful comments for complex logic
- Use English for all comments and identifiers

## Testing

- Write tests for new functionality
- Use protocol-based mocks for SFSpeechRecognizer and AVAudioSession
- Do not write tests that depend on real audio or hardware
- All unit tests should complete in under 100ms

## Platform Support

- Primary targets: iOS 13+, macOS 10.15+
- iOS 26+ features must be gated behind `@available(iOS 26.0, macOS 26.0, *)`
- Test on real devices when changing audio session or speech recognition behavior

## Questions?

- Check AGENTS.md for project-specific context
- Check REFACTOR_PLAN.md for current refactoring priorities
