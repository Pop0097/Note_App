//
//  ContentView.swift
//  awsApp
//
//  Created by Dhruv Rawat on 2021-06-07.
//

import SwiftUI

// Singleton class that stores the user's data
class UserData : ObservableObject {
    private init() {} // Private constructor
    static let shared = UserData() // Static instance of the class
    
    // The @Published tag allows us to create observable objects that automatically announce when changes occur. So we can make listeners to act on changes :)
    @Published var notes : [Note] = [] // Array stores notes
    @Published var isSignedIn : Bool = false
}

// Model for our Notes
class Note : Identifiable, ObservableObject {
    var id : String
    var name : String
    var description : String? // Optional because they can be null
    var imageName : String?
    @Published var image : Image?
    
    init(id: String, name: String, description: String? = nil /* Optional parameter */, image: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.imageName = image
    }
}

// Represents a single item in a list
struct ListRow : View {
    @ObservedObject var note : Note // Indicates that we are observing for changes in this object
    
    var body : some View { // Identifies that we are making a view to be displayed on the screen. In SwiftUI all UI stuff must be within one of these methods
        // Display image on left if present
        if (nil != note.image) {
            note.image!.resizable().frame(width: 50, height: 50) // Display image
        }
        
        VStack(alignment: .leading, spacing: 5.0) {
            Text(note.name).bold()
            
            if (nil != note.description) {
                Text(note.description!) // Expanation mark needed since this is an optional variable (We must extract its value)
            }
        }
    }
}

// Main view of the Application. What loads first
struct ContentView: View {
    @ObservedObject private var userData : UserData = .shared
    
    var body: some View {
        List {
            ForEach(userData.notes) { note in // Other form of a for loop. Same as "for note in userData.notes"
                ListRow(note: note)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = prepareTestData()
        
        ContentView()
    }
}

func prepareTestData() -> UserData {
    let userData = UserData.shared
    userData.isSignedIn = true
    let desc = "description on \n multiple lines"
    
    let n1 = Note(id: "01", name: "Hello", description: desc, image: "mic")
    let n2 = Note(id: "02", name: "New Note", description: desc, image: "phone")
    
    n1.image = Image(systemName: n1.imageName!)
    n2.image = Image(systemName: n2.imageName!)
    
    userData.notes = [ n1, n2 ]
    
    return userData
}
