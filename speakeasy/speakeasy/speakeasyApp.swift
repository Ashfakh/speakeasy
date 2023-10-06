//
//  speakeasyApp.swift
//  speakeasy
//
//  Created by Ashfakh Rithu on 06/10/23.
//

import SwiftUI
import CoreData

@main
struct SpeakEasyApp: App {
    // Create an instance of your database (or data manager).
    let recordingDB = RecordingDatabase()
    
    var body: some Scene {
        WindowGroup {
            // Start with MainView and provide the database as an environment object.
            MainView().environmentObject(recordingDB)
        }
    }
}
