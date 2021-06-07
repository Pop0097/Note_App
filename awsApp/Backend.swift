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
        }
    }
}
