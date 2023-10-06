//
//  MainView.swift
//  speakeasy
//
//  Created by Ashfakh Rithu on 06/10/23.
//

import Foundation
import SwiftUI

struct MainView: View {

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: RecordAudioView()) {
                    Text("Go to Recording")
                }
                
                NavigationLink(destination: RecordingListView()) {
                    Text("Go to Recordings List")
                }
            }
        }
    }
}

