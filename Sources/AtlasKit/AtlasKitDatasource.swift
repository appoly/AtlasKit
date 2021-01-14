//
//  AtlasKitDatasource.swift
//  AtlasKit
//
//  Created by James Wolfe on 13/08/2020.
//  Copyright © 2020 Appoly. All rights reserved.
//



import Foundation



public enum AtlasKitDataSource {
    case google(key: String)
    case apple
    case getAddress(key: String)
}


extension AtlasKitDataSource {
    public var apiKey: String? {
        switch self {
            case .google(let key):
                return key
            case .getAddress(let key):
                return key
            case .apple:
                return nil
        }
    }
}
