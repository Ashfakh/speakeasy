//
//  RecordView.swift
//  speakeasy
//
//  Created by Ashfakh Rithu on 06/10/23.
//

import SwiftUI
import AVFoundation
import Speech

struct RecordAudioView: View {
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var isPaused = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showMessage = false
    @EnvironmentObject var recordingDB: RecordingDatabase

    // Reuse the path to the audio file
    private var audioURL: URL {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let uniqueName = "audioRecording-\(Date().timeIntervalSince1970)-\(UUID().uuidString).m4a"
        return documentPath.appendingPathComponent(uniqueName)
    }
    

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                if isRecording {
                    if isPaused {
                        continueRecording()
                    } else {
                        pauseRecording()
                    }
                } else {
                    startRecording()
                }
            }) {
                Text(isRecording ? (isPaused ? "Continue Recording" : "Pause Recording") : "Start Recording")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
            
            Button(action: {
                stopRecording()
            }) {
                Text("Stop Recording")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(8)
            }
            .disabled(!isRecording)

            Text("Elapsed Time: \(Int(elapsedTime)) seconds")

            if showMessage {
                Text("Recording saved!")
                    .foregroundColor(.green)
                    .onAppear(perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showMessage = false
                        }
                    })
            }
        }
        .padding()
    }

    func startRecording() {
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if microphoneStatus != .authorized {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    self.checkAndRequestSpeechRecognitionPermission()
                } else {
                    // Handle microphone permission denial here, e.g., show an alert to the user
                }
            }
        } else {
            self.checkAndRequestSpeechRecognitionPermission()
        }
    }

    func checkAndRequestSpeechRecognitionPermission() {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        switch authStatus {
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self.actuallyStartRecording()
                    } else {
                        // Handle speech recognition permission denial here
                    }
                }
            }
        case .authorized:
            self.actuallyStartRecording()
        default:
            // Handle other cases here
            break
        }
    }

    func actuallyStartRecording() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.record()

            isRecording = true

            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                elapsedTime += 1
            }

        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        isPaused = false

        // Stop and reset timer
        timer?.invalidate()
        timer = nil
        elapsedTime = 0

        transcribeAudioToText()
    }

    func transcribeAudioToText() {
        guard let audioURL = audioRecorder?.url else {
            print("Audio URL not found!")
            return
        }

        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audioURL)

        //TODO: Fix this
//        recognizer?.recognitionTask(with: request) { (result, error) in
//            guard let result = result else {
//                print("There was an error: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//
//            // Get the transcribed text
//            let transcribedText = result.bestTranscription.formattedString
//
//
//            // Save the transcribed text to a file
//            if let transcriptionURL = saveTranscriptionToFile(text: transcribedText) {
//                      let filePathString = transcriptionURL.path
//                      recordingDB.addRecording(name: "Recording on \(Date())", filePath: filePathString)
//                  }
//            removeAudioFile(at: audioURL)
//
//        }
        
        let transcribedText = "In a room filled with echoes, I stand alone, seeking solace in the silent corners of my mind. Every face I've passed, every voice I've heard, they meld into one distant murmur. The weight of existence bears down, reminding me that time is both an ally and enemy. Yet, in this quiet moment, I find clarity. Life is not about the vastness of years but the depth of experiences. Each fleeting second, every fleeting smile, is a testament to our resilience. I am not lost; I am on a journey. A journey that's uniquely mine. And I will find my way."


            // Save the transcribed text to a file
            if let transcriptionURL = saveTranscriptionToFile(text: transcribedText) {
                      let filePathString = transcriptionURL
                      recordingDB.addRecording(name: "Transcription on \(Date())", filePath: filePathString)
                  }
            removeAudioFile(at: audioURL)
    }
    
    func saveTranscriptionToFile(text: String) -> String? {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let uniqueName = "transcription-\(Date().timeIntervalSince1970).txt"
        let fileURL = documentPath.appendingPathComponent(uniqueName)

        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Transcription saved at \(uniqueName)")
            return uniqueName
        } catch {
            print("Failed to save transcription: \(error.localizedDescription)")
            return nil
        }
    }


    
    func removeAudioFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            print("Audio file removed successfully!")
        } catch {
            print("Failed to remove audio file: \(error.localizedDescription)")
        }
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
        isPaused = true
        
        // Pause the timer
        timer?.invalidate()
    }

    func continueRecording() {
        audioRecorder?.record()
        isPaused = false
        
        // Restart the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
}


struct RecordAudioView_Previews: PreviewProvider {
    static var previews: some View {
        RecordAudioView()
    }
}
