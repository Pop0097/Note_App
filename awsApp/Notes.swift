//
//  Notes.swift
//  awsApp
//
//  Created by Dhruv Rawat on 2021-06-07.
//

import SwiftUI

// Model for our Notes
class Note : Identifiable, ObservableObject {
    var id : String
    var name : String {
        didSet {
            Backend.shared.editNote(note: self)
            Backend.shared.queryNotes()
        }
    }
    
    var description : String? {
        didSet {
            Backend.shared.editNote(note: self)
            Backend.shared.queryNotes()
        }
    }
    var imageName : String?
    @Published var image : Image?
    @Published var uiimage : UIImage?
    
    fileprivate var _data : NoteData? // Scope is only this file. Like a static global variable in C
    
    init(id: String, name: String, description: String? = nil /* Optional parameter */, image: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.imageName = image
    }
    
    convenience init(from data: NoteData) {
        self.init(id: data.id, name: data.name, description: data.description, image: data.image)
        
        if let name = self.imageName {
            // asynchronously download the image
            Backend.shared.retrieveImage(name: name) { (data) in
                // update the UI on the main thread
                DispatchQueue.main.async() {
                    let uim = UIImage(data: data)
                    self.uiimage = uim!
                    self.image = Image(uiImage: uim!)
                }
            }
        }
        
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

struct AddNoteView: View {
    // @Binding lets us declare that one value actually comes from elsewhere, and should be shared in both places.
    @Binding var isPresented: Bool
    
    var userData: UserData

    @State var name : String = "New Note"
    @State var description : String = ""
    @State var image : UIImage? // replace the previous declaration of image
    @State var showCaptureImageView = false
    
    var body: some View {
        VStack {
            Button(action: {
                self.showCaptureImageView.toggle() // Calls listener four lines down
            }) {
                Text("Choose photo")
            }.sheet(isPresented: $showCaptureImageView /* Listener */) {
                CaptureImageView(isShown: self.$showCaptureImageView, image: self.$image) // Opens capture image view
            }
            
            // Display image if selected
            if (image != nil ) {
                HStack {
                    Spacer()
                    Image(uiImage: image!)
                        .resizable()
                        .frame(width: 250, height: 200)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                    Spacer()
                }
            }
        }
        
        PlaceholderTextField("Title", text: $name)
        
        TextArea("", text: $description)
        
        Button(action: {
            self.isPresented = false

            let note = Note(id : UUID().uuidString,
                            name: self.$name.wrappedValue,
                            description: self.$description.wrappedValue)

            if let i = self.image  { // If image is picked, run this code
                note.imageName = UUID().uuidString
                note.image = Image(uiImage: i)

                // asynchronously store the image (and assume it will work)
                Backend.shared.storeImage(name: note.imageName!, image: (i.pngData())!)
            }

            // asynchronously store the note (and assume it will succeed)
            Backend.shared.createNote(note: note)

            // add the new note in our userdata, this will refresh UI
            withAnimation { self.userData.notes.append(note) }
        }) {
            Text("Create")
        }
    }
}


struct Notes: View {
    @ObservedObject private var userData : UserData = .shared
    @ObservedObject var note : Note
    
    @State var showCaptureImageView = false
    @State var image : UIImage? // replace the previous declaration of image
    
    @State var name : String = ""
    @State var description : String = ""
    
    var body: some View {
        // Display image if selected
        if (note.uiimage != nil ) {
            HStack {
                Image(uiImage: note.uiimage!)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
            }
        }
        
        PlaceholderTextField(note.name, text: $note.name)
        
        
        TextArea(nil != note.description ? note.description! : "", text: $note.description.bound)
    }
}

struct Notes_Previews: PreviewProvider {
    static var previews: some View {
        Notes(note: Note(id: "", name: ""))
    }
}
