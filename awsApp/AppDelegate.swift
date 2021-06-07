//
//  AppDelegate.swift
//  awsApp
//
//  Created by Dhruv Rawat on 2021-06-07.
//

import Foundation
import SwiftUI

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // initialize Amplify
    let _ = Backend.initialize()

    return true
}
