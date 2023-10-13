//
//  RecordingListView.swift
//  speakeasy
//
//  Created by Ashfakh Rithu on 06/10/23.
//

import Foundation
import SwiftUI

struct RecordingListView: View {
    @EnvironmentObject var recordingDB: RecordingDatabase
    
    var body: some View {
        List(recordingDB.recordings, id: \.id) { record in
            NavigationLink(destination: TranscriptionDetailView(transcription: getTranscription(for: record))) {
                Text(record.name ?? "")
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
    
    func getTranscription(for record: Recording) -> String {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let transcriptionURL = documentDirectory.appendingPathComponent(record.filePath ?? "")
        
        do {
            let transcription = try String(contentsOf: transcriptionURL, encoding: .utf8)
            return transcription
        } catch {
            print("Failed to read transcription: \(error.localizedDescription)")
            return "Error reading transcription"
        }
    }
}

class OpenAIApiClient {
    let baseURL = "https://api.openai.com/v1/engines/gpt-3.5-turbo/completions"
    let apiKey = "API_KEY" // Make sure to keep this secret and secure.
    
    func summarize(text: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: baseURL) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "Summarize the following text"],
                ["role": "user", "content": text]
            ]
        ] as [String: Any]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil,
                  let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                  let dictionary = jsonObject as? [String: Any],
                  let choices = dictionary["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let text = firstChoice["text"] as? String
            else {
                completion(nil)
                return
            }

            completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
}


struct TranscriptionDetailView: View {
    var transcription: String
    @State private var summary: String?
    @State private var showError: Bool = false

    let openAIClient = OpenAIApiClient()

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                Text(summary ?? transcription)
                    .padding()
            }
            
            if let summaryText = summary {
                Text("Summary:")
                    .font(.headline)
                    .padding(.top, 10)
                
                Text(summaryText)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            if summary == nil { // Only display the "Summarize" button if the summary isn't generated yet.
                Button("Summarize") {
                    fetchSummary(for: transcription)
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .navigationBarTitle("Transcription", displayMode: .inline)
        .alert(isPresented: $showError, content: {
            Alert(title: Text("Error"), message: Text("Failed to fetch the summary. Please try again later."), dismissButton: .default(Text("OK")))
        })
    }
    
    func fetchSummary(for text: String) {
        openAIClient.summarize(text: text) { receivedSummary in
            DispatchQueue.main.async {
                if let summaryText = receivedSummary {
                    self.summary = summaryText
                } else {
                    self.showError = true
                }
            }
        }
    }
}



