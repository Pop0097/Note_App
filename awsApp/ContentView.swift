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

// Represents a single item in a list
struct ListRow: View {
    // Indicates that we are observing for changes in this object
    @ObservedObject var note : Note
    
    // Identifies that we are making a view to be displayed on the screen. In SwiftUI all UI stuff must be within one of these methods
    var body: some View {
        HStack(alignment: .center, spacing: 5.0) {

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

// Main view of the Application. What loads first
struct ContentView: View {
    
    @ObservedObject private var userData : UserData = .shared
    
    // When the state value changes, the view invalidates its appearance and recomputes the body.
    @State var showCreateNote = false
    @State var name : String = "New Note"
    @State var description : String = "This is a new note"
    
    var body: some View {
        ZStack {
            if (userData.isSignedIn) { // View conditional on signin status
                NavigationView { // Creates a navigation bar
                    List {
                        ForEach(userData.notes) { note in // Other form of a for loop. Same as "for note in userData.notes"
                            NavigationLink(destination: Notes(note: note)) {
                                ListRow(note: note)
                            }
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
