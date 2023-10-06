//
//  RecordView.swift
//  speakeasy
//
//  Created by Ashfakh Rithu on 06/10/23.
//

import SwiftUI
import AVFoundation

struct RecordAudioView: View {
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isRecording = false
    @State private var isPlaying = false
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
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }

            Button(action: {
                if isPlaying {
                    stopPlayback()
                } else {
                    startPlayback()
                }
            }) {
                Text(isPlaying ? "Stop Playback" : "Play Recording")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(!FileManager.default.fileExists(atPath: audioURL.path))

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
            let audioSession = AVAudioSession.sharedInstance()

            do {
                try audioSession.setCategory(.record, mode: .default)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

                let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioURL = documentPath.appendingPathComponent("audioRecording.m4a")

                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 12000,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]

                audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
                audioRecorder?.record()

                isRecording = true

                // Start timer
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

            // Stop and reset timer
            timer?.invalidate()
            timer = nil
            
            elapsedTime = 0
            
            let relativePath = audioURL.lastPathComponent
            recordingDB.addRecording(name: "audioRecording-\(Date().timeIntervalSince1970)", filePath: relativePath)

            // Show the saved message
            showMessage = true
            
        }
    
    func startPlayback() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }}


struct RecordAudioView_Previews: PreviewProvider {
    static var previews: some View {
        RecordAudioView()
    }
}
