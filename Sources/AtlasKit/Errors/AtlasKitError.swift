//
//  AtlasKitError.swift
//  AtlasKit
//
//  Created by James Wolfe on 13/08/2020.
//  Copyright © 2020 Appoly. All rights reserved.
//



import Foundation



public enum AtlasKitError: Error {
    case generic
    case networkUnavailable
}


extension AtlasKitError {
    var localizedDescription: String {
        switch self {
            case .generic:
                return "Failed to lookup address"
        case .networkUnavailable:
                return "Please check your network connection and try again"
        }
    }
}
