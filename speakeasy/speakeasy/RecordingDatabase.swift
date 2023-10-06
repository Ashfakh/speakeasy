//
//  RecordinDatabase.swift
//  speakeasy
//
//  Created by Ashfakh Rithu on 06/10/23.
//

import CoreData

class RecordingDatabase: ObservableObject {
    @Published var recordings: [Recording] = [] // Assuming RecordingEntity is the name of the Core Data generated class
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "speakeasy") // Replace with your Core Data model name
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        return container
    }()
    
    
    func addRecording(name: String, filePath: String) {
        let newRecording = Recording(context: context)
        newRecording.id = UUID()
        newRecording.name = name
        newRecording.filePath = filePath
        
        do {
            try context.save()
            fetchRecordings()
        } catch {
            print("Failed to save recording: \(error.localizedDescription)")
        }
    }
    
    func fetchRecordings() {
        let request: NSFetchRequest<Recording> = Recording.fetchRequest()
        do {
            recordings = try context.fetch(request)
        } catch {
            print("Failed to fetch recordings: \(error.localizedDescription)")
        }
    }
    
    func deleteAll() {
        for recording in recordings {
            // Delete the associated audio file
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentDirectory.appendingPathComponent(recording.filePath ?? "")
            
            do {
                try FileManager.default.removeItem(at: audioURL)
            } catch {
                print("Failed to delete audio file: \(error.localizedDescription)")
            }
            
            // Delete the entry from the Core Data database
            context.delete(recording)
        }
        
        do {
            try context.save()
            fetchRecordings()
        } catch {
            print("Failed to save after deletion: \(error.localizedDescription)")
        }
    }
    
}
