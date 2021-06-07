//
//  Backend.swift
//  awsApp
//
//  Created by Dhruv Rawat on 2021-06-07.
//
import Foundation
import UIKit
import Amplify
import AmplifyPlugins

// Singleton
class Backend {
    static let shared = Backend()
    
    static func initialize() -> Backend {
        return .shared
    }
    
    private init() {
        // initialize amplify
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure()
            print("Initialized Amplify");
        } catch {
            print("Could not initialize Amplify: \(error)")
        }
        
        // Triggers when authentication status changes
        _ = Amplify.Hub.listen(to: .auth) { (payload) in

            switch payload.eventName {

                case HubPayload.EventName.Auth.signedIn:
                    print("==HUB== User signed In, update UI")
                    self.updateUserData(withSignInStatus: true)

                case HubPayload.EventName.Auth.signedOut:
                    print("==HUB== User signed Out, update UI")
                    self.updateUserData(withSignInStatus: false)

                case HubPayload.EventName.Auth.sessionExpired:
                    print("==HUB== Session expired, show sign in UI")
                    self.updateUserData(withSignInStatus: false)

                default:
                    break
            }
        }
         
        // let's check if user is signedIn or not
         _ = Amplify.Auth.fetchAuthSession { (result) in
             do {
                 let session = try result.get() // Tries to get user session
                        
                // let's update UserData and the UI
                self.updateUserData(withSignInStatus: session.isSignedIn) // Update user
             } catch {
                  print("Fetch auth session failed with error - \(error)")
            }
        }
    }
    
    public func signIn() {
        _ = Amplify.Auth.signInWithWebUI(presentationAnchor: UIApplication.shared.windows.first!, options: .preferPrivateSession()) { result in
            switch result {
            case .success(_):
                print("Sign in succeeded")
            case .failure(let error):
                print("Sign in failed \(error)")
            }
        }
    }
    
    public func signOut() {
        Amplify.Auth.signOut()
            .resultPublisher
            .sink {
                if case let .failure(authError) = $0 {
                    print("Sign out failed with error \(authError)")
                }
            }
            receiveValue: {
                print("Successfully signed out")
            }
    }
    
    // change our internal state, this triggers an UI update on the main thread
    func updateUserData(withSignInStatus status : Bool) {
        DispatchQueue.main.async() {
            let userData : UserData = .shared
            userData.isSignedIn = status

            // when user is signed in, query the database, otherwise empty our model
            if status {
                self.queryNotes()
            } else {
                userData.notes = []
            }
        }
    }
    
    // Note CRUD Methods
    
    func queryNotes() {
        _ = Amplify.API.query(request: .list(NoteData.self) /* Returns a list of all the notes in our database */) { event in // Read our database and request all notes in database
            switch event {
            case .success(let result): // If retrieved successfully
                switch result {
                case .success(let notesData):
                    print("Successfully retrieved list of Notes")

                    // convert an array of NoteData to an array of Note class instances
                    for n in notesData {
                        let note = Note.init(from: n)
                        DispatchQueue.main.async() {
                            UserData.shared.notes.append(note) // Add notes to the user's list of notes
                        }
                    }
                case .failure(let error):
                    print("Cannot retrieve result: error \(error)")
                }
            case .failure(let error):
                print("Cannot retrieve Notes: error \(error)")
            }
        }
    }
    
    func createNote(note: Note) {

        // use note.data to access the NoteData instance
        _ = Amplify.API.mutate(request: .create(note.data)) { event in // Update our database
            switch event {
            case .success(let result):
                switch result {
                case .success(let data):
                    print("Successfully created note: \(data)")
                case .failure(let error):
                    print("Got failed result with \(error.errorDescription)")
                }
            case .failure(let error):
                print("Got failed event with error \(error)")
            }
        }
    }

    func deleteNote(note: Note) {

        // use note.data to access the NoteData instance
        _ = Amplify.API.mutate(request: .delete(note.data)) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let data):
                    print("Successfully deleted note: \(data)")
                case .failure(let error):
                    print("Got failed result with \(error.errorDescription)")
                }
            case .failure(let error):
                print("Got failed event with error \(error)")
            }
        }
    }
    
    // Image CRUD Methods
    
    // Uploads data to AWS
    func storeImage(name: String, image: Data) {

        // let options = StorageUploadDataRequest.Options(accessLevel: .private)
        let _ = Amplify.Storage.uploadData(key: name, data: image,// options: options,
            progressListener: { progress in
                // optionlly update a progress bar here
            }, resultListener: { event in
                switch event {
                case .success(let data):
                    print("Image upload completed: \(data)")
                case .failure(let storageError):
                    print("Image upload failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
            }
        })
    }
    
    // Get image from AWS
    func retrieveImage(name: String, completed: @escaping (Data) -> Void) {
        let _ = Amplify.Storage.downloadData(key: name,
            progressListener: { progress in
                // in case you want to monitor progress
            }, resultListener: { (event) in
                switch event {
                case let .success(data):
                    print("Image \(name) loaded")
                    completed(data)
                case let .failure(storageError):
                    print("Can not download image: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                }
            }
        )
    }
    
    // Delete image from AWS
    func deleteImage(name: String) {
        let _ = Amplify.Storage.remove(key: name,
            resultListener: { (event) in
                switch event {
                case let .success(data):
                    print("Image \(data) deleted")
                case let .failure(storageError):
                    print("Can not delete image: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                }
            }
        )
    }

}
