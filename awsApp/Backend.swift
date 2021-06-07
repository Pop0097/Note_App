//
//  Backend.swift
//  awsApp
//
//  Created by Dhruv Rawat on 2021-06-07.
//

import Foundation
import UIKit
import Amplify

// Singleton
class Backend {
    static let shared = Backend()
    
    static func initialize() -> Backend {
        return .shared
    }
    
    private init() {
      // initialize amplify
      do {
        try Amplify.configure()
        print("Initialized Amplify");
      } catch {
        print("Could not initialize Amplify: \(error)")
      }
    }
}
