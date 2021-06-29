//
//  ConvertBoundOptionalToBoundLiteral.swift
//  awsApp
//
//  Created by Dhruv Rawat on 2021-06-08.
//

import Foundation

extension Optional where Wrapped == String {
    var _bound: String? {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    public var bound: String {
        get {
            return _bound ?? ""
        }
        set {
            _bound = newValue.isEmpty ? nil : newValue
        }
    }
}
