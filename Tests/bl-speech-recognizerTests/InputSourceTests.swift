import Foundation
import Testing
@testable import bl_speech_recognizer

@Suite("InputSource Tests")
struct InputSourceTests {

  @Test("InputSourceFactory creates MicrophoneInputSource")
  func testCreateMicrophoneInputSource() {
    let inputSource = InputSourceFactory.create(inputSource: .microphone)
    #expect(inputSource is MicrophoneInputSource)
  }

  @Test("InputSourceFactory creates AudioFileInput")
  func testCreateAudioFileInput() {
    let url = URL(fileURLWithPath: "/tmp/test.m4a")
    let inputSource = InputSourceFactory.create(inputSource: .audioFile(url))
    #expect(inputSource is AudioFileInput)
  }

  @Test("InputSourceFactory creates CustomInputSource")
  func testCreateCustomInputSource() {
    let inputSource = InputSourceFactory.create(inputSource: .customStream)
    #expect(inputSource is CustomInputSource)
  }

  @Test("InputSourceFactory accepts callbacks for microphone")
  func testCreateMicrophoneWithCallbacks() {
    var speakDetected = false
    var silenceDetected = false

    let inputSource = InputSourceFactory.create(
      inputSource: .microphone,
      speakDetectedCallback: { speakDetected = true },
      silenceDetectedCallback: { silenceDetected = true }
    )

    #expect(inputSource is MicrophoneInputSource)
    #expect(speakDetected == false)
    #expect(silenceDetected == false)
  }
}
