import Foundation
import Testing
@testable import bl_speech_recognizer

@Suite("Public API Tests")
struct PublicAPITests {

  @Test("ContinuousSpeechRecognizer can be initialized")
  func testContinuousSpeechRecognizerInit() {
    _ = ContinuousSpeechRecognizer()
  }

  @Test("CommandSpeechRecognizer can be initialized")
  func testCommandSpeechRecognizerInit() {
    _ = CommandSpeechRecognizer()
  }

  @Test("InterruptibleChat can be initialized")
  func testInterruptibleChatInit() {
    _ = InterruptibleChat(inputType: .microphone, activateSSML: false)
  }

  @Test("InterruptibleChat can list voices")
  func testInterruptibleChatListVoices() {
    let voices = InterruptibleChat.listVoices()
    #expect(voices.isEmpty == false)
  }

  @Test("InterruptibleChat voices contain expected languages")
  func testInterruptibleChatVoicesLanguages() {
    let voices = InterruptibleChat.listVoices()
    let languages = Set(voices.map { $0.language })
    #expect(languages.isEmpty == false)
  }
}
