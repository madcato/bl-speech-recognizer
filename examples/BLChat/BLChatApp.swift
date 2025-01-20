//
//  BLChatApp.swift
//  BLChat
//
//  Created by Daniel Vela on 4/1/25.
//

import SwiftUI

@main
struct BLChatApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  var body: some View {
    NavigationView {
      TabView {
        NavigationView {
          ContinuousSpeechRecognitionView()
        }
        .tabItem {
          Label("Continuous", systemImage: "waveform.circle")
        }
        NavigationView {
          CommandSpeechRecognitionView()
        }
        .tabItem {
          Label("Command", systemImage: "mic.circle")
        }
        NavigationView {
          InterruptibleChatView()
        }
        .tabItem {
          Label("Interruptible", systemImage: "bubble.left")
        }
      }
    }
  }
}

// MARK: - Preview
struct SpeechRecognitionView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
