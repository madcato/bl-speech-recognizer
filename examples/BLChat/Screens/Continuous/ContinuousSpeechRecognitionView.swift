//
//  ContinuousSpeechRecognitionView.swift
//  BLChat
//
//  Created by Daniel Vela on 4/1/25.
//

import SwiftUI

// MARK: - View
struct ContinuousSpeechRecognitionView: View {
  @StateObject private var viewModel = ContinuousSpeechRecognitionViewModel()
  
  var body: some View {
    VStack {
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
      
      Spacer()
      
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
    .navigationTitle("Continuous")
  }
}

// MARK: - Preview
struct ContinuousSpeechRecognitionView_Previews: PreviewProvider {
  static var previews: some View {
    ContinuousSpeechRecognitionView()
  }
}
