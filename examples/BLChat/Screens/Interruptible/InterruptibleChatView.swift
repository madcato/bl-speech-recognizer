//
//  InterruptibleChatView.swift
//  BLChat
//
//  Created by Daniel Vela on 4/1/25.
//

import SwiftUI
import MediaPlayer

// MARK: - View
struct InterruptibleChatView: View {
  @StateObject private var viewModel = InterruptibleChatViewModel()
  
  var body: some View {
    VStack {
      // State
      HStack {
        Image(systemName: "mic")
          .resizable()
          .scaledToFit()
          .foregroundColor(viewModel.listening ? .blue : .gray)
          .frame(width: 100, height: 50)
          .symbolEffect(.variableColor, options: viewModel.listening ? .repeating : .default, value: viewModel.listening)

        Image(systemName: "waveform")
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 50)
          .foregroundColor(.blue)
          .symbolVariant(.fill)
          .symbolEffect(.bounce.down, options: .repeating, isActive: viewModel.speaking)
        }
      // Text View
      ScrollView {
        Text(viewModel.recognizedText)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(.systemGray))
          .cornerRadius(10)
          .padding()
          .alert(isPresented: $viewModel.showError) {
            Alert(title: Text("Error"), message: Text(viewModel.errorText))
          }
      }

      Text("Select voice:")
      // Voice Selector
      Picker("Select Voice", selection: $viewModel.selectedVoice) {
        ForEach(viewModel.availableVoices, id: \.self) { voice in
          HStack {
            Text(voice.name)
            Text("(\(voice.language))")
          }.tag(voice)
        }
      }
#if os(iOS)
      .pickerStyle(WheelPickerStyle())
#elseif os(macOS)
      .pickerStyle(DefaultPickerStyle())
#endif
      .onChange(of: viewModel.selectedVoice!, initial: true) { newVoice, _  in
        viewModel.selectVoice(newVoice)
      }
      .padding()

      // Record Button
      Button(action: {
        if viewModel.isRecording {
          viewModel.stopRecording()
        } else {
          viewModel.startRecording()
        }
      }) {
        Circle()
          .fill(viewModel.isRecording ? Color.red : Color.blue)
          .frame(width: 80, height: 80)
          .overlay(
            Image(systemName: "mic.fill")
              .foregroundColor(.white)
              .font(.system(size: 36))
          )
          .scaleEffect(viewModel.isRecording ? 1.2 : 1.0)
          .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
      }
      .padding()
    }
    .navigationTitle("Interruptible Chat")
  }
}

// MARK: - Preview
struct InterruptibleChatView_Previews: PreviewProvider {
  static var previews: some View {
    InterruptibleChatView()
  }
}
