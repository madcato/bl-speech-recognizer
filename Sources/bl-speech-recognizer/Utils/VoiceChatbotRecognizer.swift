//
//  VoiceChatbotRecognizer.swift
//  bl-speech-recognizer
//
//  Created by Dani Vela on 13/1/26.
//

import AVFoundation
import Speech

// Clase principal para manejar el reconocimiento de voz en vivo para un chatbot
@available(iOS 26.0, macOS 26.0, *)
class VoiceChatbotRecognizer {
  public weak var delegate: BLSpeechRecognizerDelegate?
  
  private var audioEngine = AVAudioEngine()
  private let audioQueue = DispatchQueue(label: "com.example.audioProcessing", qos: .userInitiated)
  
  private let speechAnalyzer: SpeechAnalyzer
  private let transcriber: SpeechTranscriber
  private let detector: SpeechDetector
  private let inputNode: AVAudioInputNode
  private var recognitionTask: Task<Void, Error>?
  private var detectorTask: Task<Void, Error>?
  private let locale: Locale
  // The format of the audio.
  private var analyzerFormat: AVAudioFormat?
  private let converter = BufferConverter()
  
  init(locale: Locale = .current) {
    self.locale = locale
    // Configura el transcriber con preset para transcripción en vivo progresiva (ideal para chatbot)
    transcriber = SpeechTranscriber(
      locale: locale,  // Cambia al idioma deseado, ej. "en-US" para inglés
      preset: .timeIndexedProgressiveTranscription
    )
    
    detector = SpeechDetector(
      detectionOptions: SpeechDetector.DetectionOptions(
        sensitivityLevel: .medium          // Más agresivo (baja latencia, más falsos positivos)
      ),
      reportResults: true
    )
    
    // Configura el analyzer con opciones para baja latencia
    speechAnalyzer = SpeechAnalyzer(
      modules: [detector, transcriber],
      options: .init(
        priority: .high,
        modelRetention: .processLifetime  // Mantiene el modelo cargado para sesiones rápidas
      )
    )
    
    // Obtiene el nodo de entrada de audio
    inputNode = audioEngine.inputNode
  }
  
  // Inicia la captura y procesamiento de audio
  func start() async throws {
    guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale.current) else {
      /* Note unsupported language */
      fatalError("Not suported language")
    }
    
#if !os(macOS)
    // Configura la sesión de audio
    let audioSession = AVAudioSession.sharedInstance()
    var options: AVAudioSession.CategoryOptions = [
      .allowBluetoothHFP,     // Allow Hands Free Devices
      .allowBluetoothA2DP,    // AirPods, high-quality auriculars
      .allowAirPlay,          // AirPods Pro/Max/etc
      .duckOthers             // Lower other apps volume
      //                                   .mixWithOthers        // Opyional: if you wnat to mix with other apps
     ]
    // Detecta si hay Bluetooth conectado (o AirPods)
    let isBluetoothConnected = audioSession.currentRoute.outputs.contains { output in
        output.portType == .bluetoothHFP || output.portType == .bluetoothA2DP
    }
    
    if !isBluetoothConnected {
        // Solo fuerza speaker cuando NO hay Bluetooth → evita romper mic de AirPods
        options.insert(.defaultToSpeaker)
    }

    try audioSession.setCategory(AVAudioSession.Category.playAndRecord,
                                 mode: .voiceChat,
                                 options: options)
    
#if os(watchOS)
    audioSession.activate(completionHandler: { done, error in
      if let error = error {
        print(SpeechRecognizerError.auidoPropertiesError.message)
      }
    })
#endif
    if #available(iOS 18.2, *) {
      print("AVAudioSessionCancelledInputAvailable: \(audioSession.isEchoCancelledInputAvailable)")
      
      if audioSession.isEchoCancelledInputAvailable {
        try audioSession.setPrefersEchoCancelledInput(true)
      }
    }
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    
    audioEngine.isAutoShutdownEnabled = false
    
    if !isBluetoothConnected {
      // AEC: Enable voice processing if available
      var voiceProcessingEnabled = false
      if #available(iOS 16.0, macOS 14.0, *) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
          try audioEngine.inputNode.setVoiceProcessingEnabled(true)
          voiceProcessingEnabled = true
          if #available(iOS 17.0, macOS 14.0, *) {
            audioEngine.inputNode.voiceProcessingOtherAudioDuckingConfiguration = AVAudioVoiceProcessingOtherAudioDuckingConfiguration(enableAdvancedDucking: true, duckingLevel: .max)
          }
          print("[MicrophoneInputSource] Voice processing enabled successfully")
        } catch {
          print("[MicrophoneInputSource] Voice processing failed, disabling: \(error)")
          voiceProcessingEnabled = false
        }
      }

      // Only enable AGC if voice processing is active
      if voiceProcessingEnabled {
        inputNode.isVoiceProcessingAGCEnabled = true
      }
    }
#endif
    // Inicia el engine
    try audioEngine.prepare()
    try audioEngine.start()
    
    // Configura el formato de audio (buffer pequeño para baja latencia)
    // Set up the format for recording and add a tap to the audio engine's input node
    let audioFormat = inputNode.inputFormat(forBus: 0)  // 11
    guard audioFormat.sampleRate > 0 else {
      throw SpeechRecognizerError.audioInputFailure("Invalid audio format: Sample rate is 0 Hz. Don't use iOS Simulator.")
    }
    
    self.analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [detector, transcriber])
    
    // Instala un tap en el inputNode para capturar buffers
    inputNode.installTap(onBus: 0, bufferSize: 512, format: audioFormat) { [weak self] buffer, time in
      self?.audioQueue.async {
        self?.processAudioBuffer(buffer)
      }
    }
    
    try await speechAnalyzer.prepareToAnalyze(in: self.analyzerFormat )
    
    // Crea un AsyncStream para alimentar el analyzer
    let (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
    
    // Inicia el analyzer
    recognitionTask = Task {
      do {
        try await speechAnalyzer.start(inputSequence: inputSequence)
        
        // Procesa resultados en tiempo real
        for try await result in transcriber.results {
          let bestTranscription = result.text // an AttributedString
          let isFinal = result.isFinal
          let plainTextBestTranscription = String(bestTranscription.characters) // a String
          print("IsFinal: \(isFinal), Recognized: \(plainTextBestTranscription)")
          self.delegate?.recognized(text: plainTextBestTranscription, isFinal: isFinal)
        }
        
        
      } catch {
        self.delegate?.speechRecognizer(error: error)
      }
    }
    
    detectorTask = Task {
      // Procesa resultados en tiempo real
      for try await result in detector.results {
        print("Detector: \(result)")
      }
    }
    
    // El inputBuilder se usa en processAudioBuffer para enviar buffers
    self.inputBuilder = inputBuilder
  }
  
  private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
  
  // Procesa cada buffer de audio capturado
  private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
    guard let inputBuilder = inputBuilder, let analyzerFormat = self.analyzerFormat else { return }
    guard let converted = try? self.converter.convertBuffer(buffer, to: analyzerFormat) else { return }
    inputBuilder.yield(AnalyzerInput(buffer: converted))
  }
  
  // Detiene el reconocimiento
  func stop() async {
    audioEngine.stop()
    inputNode.removeTap(onBus: 0)
    inputBuilder?.finish()
    recognitionTask?.cancel()
    await speechAnalyzer.cancelAndFinishNow()
    
#if !os(macOS)
    do {
      try AVAudioSession.sharedInstance().setActive(false)
    } catch {
      print("Error al desactivar sesión de audio: \(error)")
    }
#endif
    
    print("Reconocimiento detenido")
  }
}


//// Ejemplo de uso (en tu app, ej. en un ViewController o main)
//func main() async {
//  let recognizer = VoiceChatbotRecognizer()
//
//  await recognizer.requestPermissions()
//
//  do {
//    try await recognizer.prepareAnalyzer()
//    try await recognizer.startRecognition()
//
//    // Espera unos segundos para probar (en una app real, maneja con botones o eventos)
//    try await Task.sleep(for: .seconds(30))  // Prueba hablando durante 30s
//
//    recognizer.stopRecognition()
//  } catch {
//    Logger.error("Error general: \(error.localizedDescription)")
//  }
//}
//
