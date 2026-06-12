import Foundation
import Testing
@testable import bl_speech_recognizer

@Suite("Buffer Tests")
struct BufferTests {

  @Test("BLResponseStringBuffer accumulates text")
  func testResponseStringBufferAccumulation() {
    let buffer = BLResponseStringBuffer(minLength: 0)
    buffer.onMessageReceived(text: "Hello")
    buffer.onMessageReceived(text: " world")

    #expect(buffer.accumulatedText == "Hello world")
  }

  @Test("BLResponseStringBuffer flushes all text")
  func testResponseStringBufferFlushAll() {
    let buffer = BLResponseStringBuffer(minLength: 0)
    buffer.onMessageReceived(text: "Hello world")

    var flushedText: String = ""
    buffer.flush(all: true) { text in
      flushedText = text
    }

    #expect(flushedText == "Hello world")
    #expect(buffer.accumulatedText.isEmpty)
  }

  @Test("BLResponseStringBuffer flushes complete sentence")
  func testResponseStringBufferFlushSentence() {
    let buffer = BLResponseStringBuffer(minLength: 0)
    buffer.onMessageReceived(text: "Hello world.")

    var flushedText: String = ""
    buffer.flush(all: false) { text in
      flushedText = text
    }

    #expect(flushedText == "Hello world.")
    #expect(buffer.accumulatedText.isEmpty)
  }

  @Test("BLResponseStringBuffer flushes at clause boundary")
  func testResponseStringBufferFlushClause() {
    let buffer = BLResponseStringBuffer(minLength: 0)
    buffer.onMessageReceived(text: "Hello, world and universe. This is more text.")

    var flushedText: String = ""
    buffer.flush(all: false) { text in
      flushedText = text
    }

    #expect(flushedText == "Hello, world and universe. ")
    #expect(buffer.accumulatedText == "This is more text.")
  }

  @Test("BLResponseStringBuffer does not flush below minLength")
  func testResponseStringBufferMinLength() {
    let buffer = BLResponseStringBuffer(minLength: 10)
    buffer.onMessageReceived(text: "Hi.")

    var flushed = false
    buffer.flush(all: false) { _ in
      flushed = true
    }

    #expect(flushed == false)
    #expect(buffer.accumulatedText == "Hi.")
  }

  @Test("BLResponseStringBuffer reset works")
  func testResponseStringBufferReset() {
    var buffer: BLStringBuffer = BLResponseStringBuffer(minLength: 0)
    buffer.onMessageReceived(text: "Hello")
    buffer.reset()

    #expect(buffer.accumulatedText.isEmpty)
  }

}
