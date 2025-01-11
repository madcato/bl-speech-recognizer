//
//  CommandSpeechRecognitionView.swift
//  BLChat
//
//  Created by Daniel Vela on 4/1/25.
//

import SwiftUI

// MARK: - View
struct CommandSpeechRecognitionView: View {
  @StateObject private var viewModel = CommandSpeechRecognitionViewModel()
  
  var optionsView: some View {
    ForEach(viewModel.options, id: \.self) { option in
      Text(option)
        .padding()
        .frame(maxWidth: .infinity)
        .background(viewModel.selectedOption == option ? Color.blue.opacity(0.3) : Color.clear)
        .cornerRadius(10)
    }
    .padding(.horizontal)
  }
  
  var recordButtonView: some View {
    Button(action: {
      if viewModel.isRecording {
        viewModel.stopRecording()
        viewModel.deselectOption()
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
  
  var body: some View {
    VStack {
      Text("Press the button and speak one of the options")
      Spacer()
      optionsView
      Spacer()
      recordButtonView
    }
    .navigationTitle("Command")
  }
}

// MARK: - Preview
struct CommandSpeechRecognitionView_Previews: PreviewProvider {
  static var previews: some View {
    CommandSpeechRecognitionView()
  }
}
