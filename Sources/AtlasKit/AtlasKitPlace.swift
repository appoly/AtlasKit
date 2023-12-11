//
//  AtlasKitPlace.swift
//  AtlasKit
//
//  Created by James Wolfe on 13/08/2020.
//  Copyright © 2020 Appoly. All rights reserved.
//



import Foundation
import CoreLocation



public class AtlasKitPlace {
    
    // MARK: - Variables
    
    public var getAddressId: String?
    public var streetAddress: String?
    public var city: String?
    public var postcode: String?
    public var state: String?
    public var country: String?
    public var location: CLLocationCoordinate2D?
    
    public var formattedAddress: String {
        return ([streetAddress, city, postcode, state, country].filter({ $0 != nil}) as! [String]).joined(separator: ", ")
    }
    
    
    
    // MARK: - Initializer
    
    public init(streetAddress: String? = nil, city: String? = nil, postcode: String? = nil, state: String? = nil, country: String? = nil, location: CLLocationCoordinate2D? = nil) {
        self.streetAddress = streetAddress
        self.city = city
        self.postcode = postcode
        self.state = state
        self.country = country
        self.location = location
    }
}
