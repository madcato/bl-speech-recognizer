# Audio Device Change Handling in bl-speech-recognizer

## Problema Resuelto

La librería `bl-speech-recognizer` ahora maneja correctamente los cambios de dispositivos de audio en tiempo real. Anteriormente, cuando un usuario cambiaba la fuente de audio (por ejemplo, de altavoces internos a AirPods), el reconocimiento de voz y la síntesis dejaban de funcionar correctamente.

## Solución Implementada

### 1. Detección Automática de Cambios de Dispositivos

La clase `MicrophoneInputSource` ahora incluye:

- **macOS**: Usa notificaciones de Core Audio para detectar cambios en dispositivos de entrada y salida
- **iOS**: Usa notificaciones de `AVAudioSession` para detectar cambios de ruta y interrupciones

### 2. Reinicialización Automática del Audio Engine

Cuando se detecta un cambio de dispositivo:
1. El `AVAudioEngine` actual se detiene de forma controlada
2. Se espera 0.5 segundos para que el cambio de dispositivo se complete
3. Se reinicializa el audio engine con la nueva configuración
4. El reconocimiento continúa automáticamente

### 3. Monitoreo de Dispositivos

La nueva clase `AudioDeviceMonitor` proporciona:
- Información sobre dispositivos de entrada y salida actuales
- Funciones de debugging para imprimir información detallada de audio
- Compatibilidad multiplataforma (macOS e iOS)

## Uso

### Uso Básico (Sin Cambios)

El uso de `InterruptibleChat` permanece igual:

```swift
let chat = InterruptibleChat(
    inputType: .microphone,
    locale: .current,
    activateSSML: false
)

chat.start(completion: { result in
    // Manejar resultado
}, event: { event in
    // Manejar eventos
})
```

### Monitoreo de Dispositivos

```swift
// Obtener información de dispositivos actuales
let inputDevice = AudioDeviceMonitor.getCurrentInputDevice()
let outputDevice = AudioDeviceMonitor.getCurrentOutputDevice()

// Imprimir información detallada para debugging
AudioDeviceMonitor.printCurrentAudioDevices()
```

### Ejemplo Completo

Consulta `AudioDeviceChangeExample.swift` para un ejemplo completo con UI que demuestra:
- Inicio y parada del reconocimiento
- Pruebas de síntesis de voz
- Monitoreo en tiempo real de cambios de dispositivos
- Visualización del estado actual

## Casos de Uso Soportados

### macOS
- ✅ Cambio de Mac Mini altavoces internos a AirPods
- ✅ Cambio de AirPods Max a altavoces del monitor
- ✅ Conexión/desconexión de dispositivos USB
- ✅ Cambios entre dispositivos Bluetooth

### iOS
- ✅ Conexión/desconexión de AirPods
- ✅ Cambios entre altavoces y auriculares
- ✅ Interrupciones por llamadas telefónicas
- ✅ Cambios de ruta de audio del sistema

## Debugging

### Logs Informativos

La implementación incluye logs detallados:

```
[MicrophoneInputSource] Audio device change detected
[MicrophoneInputSource] Restarting audio engine due to device change
[MicrophoneInputSource] Audio engine restarted successfully
[AudioDeviceMonitor] Current input device: AirPods Pro
[AudioDeviceMonitor] Current output device: AirPods Pro
```

### Verificar Estado del Audio

```swift
// En tu ViewModel o controlador
func checkAudioStatus() {
    AudioDeviceMonitor.printCurrentAudioDevices()
}
```

## Consideraciones de Rendimiento

- La reinicialización del audio engine introduce una latencia mínima (~0.5 segundos)
- Los cambios de dispositivo son detectados inmediatamente
- No hay impacto en el rendimiento cuando no hay cambios de dispositivos
- La implementación usa notificaciones del sistema, no polling

## Manejo de Errores

Los errores relacionados con cambios de dispositivos se reportan a través del delegate:

```swift
// En tu implementación de BLSpeechRecognizerDelegate
func speechRecognizer(error: any Error) {
    if let error = error as? SpeechRecognizerError,
       case .audioDeviceChangeError(let message) = error {
        print("Error de cambio de dispositivo: \(message)")
        // Manejar error específico
    }
}
```

## Limitaciones

1. **Latencia temporal**: Hay una breve interrupción (~0.5s) durante el cambio de dispositivo
2. **macOS Simulator**: Los cambios de dispositivo no se pueden simular completamente
3. **Dispositivos incompatibles**: Algunos dispositivos de audio muy antiguos pueden no ser detectados correctamente

## Testing

Para probar la funcionalidad:

1. Ejecuta la app en un dispositivo físico (no simulador)
2. Inicia el reconocimiento de voz
3. Cambia el dispositivo de audio (conecta/desconecta AirPods, etc.)
4. Verifica que el reconocimiento continúe funcionando
5. Revisa los logs en la consola para confirmar la detección del cambio

El ejemplo `AudioDeviceChangeExample` proporciona una interfaz visual para facilitar las pruebas.