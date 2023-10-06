//
//  RecordingListView.swift
//  speakeasy
//
//  Created by Ashfakh Rithu on 06/10/23.
//

import Foundation
import SwiftUI
import AVFoundation

struct RecordingListView: View {
    @EnvironmentObject var recordingDB: RecordingDatabase
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        List(recordingDB.recordings, id: \.id) { record in
            HStack {
                Text(record.name ?? "")
                Spacer()
                Button("Play") {
                    playRecording(for:  record)
                    // Play the recording using audioURL
                }
            }
        }
        
        Button("Delete All") {
            recordingDB.deleteAll()
        }
        .padding()
        .foregroundColor(.white)
        .background(Color.red)
        .cornerRadius(8)
    }
    
    
    func playRecording(for record: Recording) {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentDirectory.appendingPathComponent(record.filePath ?? "")
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioPlayer?.play()
            } catch {
                print("Failed to play recording: \(error.localizedDescription)")
            }
        }
}
