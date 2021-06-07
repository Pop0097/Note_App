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
    
    fileprivate var _data : NoteData? // Scope is only this file. Like a static global variable in C
    
    init(id: String, name: String, description: String? = nil /* Optional parameter */, image: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.imageName = image
    }
    
    convenience init(from data: NoteData) {
        self.init(id: data.id, name: data.name, description: data.description, image: data.image)
        
        // Store API object
        self._data = data
    }

    // access the privately stored NoteData or build one if we don't have one.
    var data : NoteData {

        if (_data == nil) {
            _data = NoteData(id: self.id,
                            name: self.name,
                            description: self.description,
                            image: self.imageName)
        }

        return _data!
    }
}

// Represents a single item in a list
struct ListRow: View {
    // Indicates that we are observing for changes in this object
    @ObservedObject var note : Note
    
    // Identifies that we are making a view to be displayed on the screen. In SwiftUI all UI stuff must be within one of these methods
    var body: some View {
        return HStack(alignment: .center, spacing: 5.0) {

            // Display image on left if present
            if (note.image != nil) {
                note.image!
                .resizable()
                .frame(width: 50, height: 50) // Display image
            }

            // the right part is a vertical stack with the title and description
            VStack(alignment: .leading, spacing: 5.0) {
                Text(note.name)
                .bold()

                if ((note.description) != nil) {
                    Text(note.description!) // Expanation mark needed since this is an optional variable (We must extract its value)
                }
            }
        }
    }
}

struct SignInButton: View {
    var body: some View {
        Button(action: { Backend.shared.signIn() /* Specifies function that will be called when pressed */}){
            HStack {
                Image(systemName: "person.fill")
                    .scaleEffect(1.5)
                    .padding()
                Text("Sign In")
                    .font(.largeTitle)
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.green)
            .cornerRadius(30)
        }
    }
}

struct SignOutButton : View {
    var body: some View {
        Button(action: { Backend.shared.signOut() }) {
            Text("Sign Out")
        }
    }
}

struct AddNoteView: View {
    // @Binding lets us declare that one value actually comes from elsewhere, and should be shared in both places.
    @Binding var isPresented: Bool
    
    var userData: UserData

    @State var name : String = "New Note"
    @State var description : String = "This is a new note"
    @State var image : String = "image"
    
    var body: some View {
        Form {
            Section(header: Text("TEXT")) {
                TextField("Name", text: $name)
                TextField("Name", text: $description)
            }

            Section(header: Text("PICTURE")) {
                TextField("Name", text: $image)
            }

            Section {
                Button(action: {
                    self.isPresented = false
                    
                    // Creates new NoteData object
                    let noteData = NoteData(id : UUID().uuidString,
                                            name: self.$name.wrappedValue,
                                            description: self.$description.wrappedValue)
                    
                    let note = Note(from: noteData) // Makes note

                    // asynchronously store the note (and assume it will succeed)
                    Backend.shared.createNote(note: note)

                    // add the new note in our userdata, this will refresh UI
                    self.userData.notes.append(note)
                }) {
                    Text("Create this note")
                }
            }
        }
    }
}

// Main view of the Application. What loads first
struct ContentView: View {
    
    @ObservedObject private var userData : UserData = .shared
    
    // When the state value changes, the view invalidates its appearance and recomputes the body.
    @State var showCreateNote = false
    @State var name : String = "New Note"
    @State var description : String = "This is a new note"
    @State var image : String = "image"
    
    var body: some View {
        ZStack {
            if (userData.isSignedIn) { // View conditional on signin status
                NavigationView { // Creates a navigation bar
                    List {
                        ForEach(userData.notes) { note in // Other form of a for loop. Same as "for note in userData.notes"
                            ListRow(note: note)
                        }.onDelete { indices in
                            indices.forEach {
                                // removing from user data will refresh UI
                                let note = self.userData.notes.remove(at: $0)

                                // asynchronously remove from database
                                Backend.shared.deleteNote(note: note)
                            }
                        }
                    }
                    .navigationBarTitle(Text("Notes"))
                    .navigationBarItems(leading: SignOutButton(), trailing: Button(action: {
                        self.showCreateNote.toggle() // Toggles this event (just below)
                    }) {
                        Image(systemName: "plus")
                    })
                }.sheet(isPresented: $showCreateNote /* Listener event */) {
                    AddNoteView(isPresented: self.$showCreateNote, userData: self.userData)
                }
            } else {
                SignInButton()
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


