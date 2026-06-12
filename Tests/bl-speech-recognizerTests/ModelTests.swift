import Foundation
import Testing
@testable import bl_speech_recognizer

@Suite("Model Tests")
struct ModelTests {

  @Test("SpeechRecognitionResult can be created")
  func testSpeechRecognitionResultCreation() {
    let result = SpeechRecognitionResult(
      transcription: "Hello world",
      confidence: 0.95,
      timestamp: 0.0,
      wordConfidence: [:],
      wordTimestamps: [:],
      wordTranscriptions: [:],
      words: ["Hello", "world"],
      utteranceId: "test-1",
      isInterrupted: false,
      isPaused: false,
      isStopped: false,
      isTranscribing: true,
      isTranscribingFinished: false,
      isTranscribingStarted: true,
      isTranscribingStopped: false,
      isFinal: false
    )

    #expect(result.transcription == "Hello world")
    #expect(result.confidence == 0.95)
    #expect(result.isFinal == false)
    #expect(result.words.count == 2)
  }

  @Test("SpeechRecognizerError provides correct descriptions")
  func testSpeechRecognizerErrorDescriptions() {
    #expect(SpeechRecognizerError.speechRecognizerNotAvailable.errorDescription == "Speech recognizer is not available for this locale.")
    #expect(SpeechRecognizerError.userDenied.errorDescription == "User denied speech recognition permission.")
    #expect(SpeechRecognizerError.notDetermined.errorDescription == "Speech recognition authorization is not determined.")
  }

  @Test("SpeechRecognizerError with associated value includes message")
  func testSpeechRecognizerErrorWithMessage() {
    let error = SpeechRecognizerError.auidoPropertiesError("Invalid format")
    #expect(error.errorDescription?.contains("Invalid format") == true)
  }

  @Test("Voice can be created with required properties")
  func testVoiceCreation() {
    let voice = Voice(
      language: "en-US",
      identifier: "com.apple.voice.en-US",
      name: "Samantha",
      gender: .female,
      quality: .enhanced
    )

    #expect(voice.language == "en-US")
    #expect(voice.identifier == "com.apple.voice.en-US")
    #expect(voice.name == "Samantha")
    #expect(voice.rate == nil)
    #expect(voice.pitchMultiplier == nil)
    #expect(voice.gender == .female)
    #expect(voice.quality == .enhanced)
  }

  @Test("Voice can be created with optional properties")
  func testVoiceWithOptionalProperties() {
    var voice = Voice(
      language: "es-ES",
      identifier: "com.apple.voice.es-ES",
      name: "Monica",
      gender: .female,
      quality: .default
    )
    voice.rate = 0.5
    voice.pitchMultiplier = 1.2

    #expect(voice.rate == 0.5)
    #expect(voice.pitchMultiplier == 1.2)
  }

  @Test("Voice conforms to Hashable")
  func testVoiceHashable() {
    let voice1 = Voice(language: "en-US", identifier: "id1", name: "Voice1", gender: .unspecified, quality: .default)
    let voice2 = Voice(language: "en-US", identifier: "id1", name: "Voice1", gender: .unspecified, quality: .default)
    let voice3 = Voice(language: "es-ES", identifier: "id2", name: "Voice2", gender: .male, quality: .premium)

    #expect(voice1 == voice2)
    #expect(voice1 != voice3)
    #expect(voice1.hashValue == voice2.hashValue)
  }

  @Test("VoiceGender has all cases")
  func testVoiceGenderCases() {
    #expect(VoiceGender.male.rawValue == "Male")
    #expect(VoiceGender.female.rawValue == "Female")
    #expect(VoiceGender.unspecified.rawValue == "Unspecified")
    #expect(VoiceGender.allCases.count == 3)
  }

  @Test("VoiceQuality has all cases")
  func testVoiceQualityCases() {
    #expect(VoiceQuality.default.rawValue == "Default")
    #expect(VoiceQuality.enhanced.rawValue == "Enhanced")
    #expect(VoiceQuality.premium.rawValue == "Premium")
    #expect(VoiceQuality.allCases.count == 3)
  }
}
