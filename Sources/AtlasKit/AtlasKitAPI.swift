//
//  AtlasKitAPI.swift
//  
//
//  Created by James Wolfe on 07/01/2022.
//



import Foundation



enum AtlasKitAPI {
    
    // MARK: - Cases
    
    case googleSearch(term: String, apiKey: String)
    case getAddressSearch(term: String, apiKey: String)
    
    
    
    // MARK: - Variables
    
    var url: URL {
        switch self {
            case .googleSearch(let term, let apiKey):
                return URL(string: "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?term=\(term)&inputtype=textquery&locationbias=ipbias&fields=formatted_address,name,geometry&key=\(apiKey)")!
            case .getAddressSearch(let term, let apiKey):
                return URL(string: "https://api.getaddress.io/find/\(term)?api-key=\(apiKey)")!
        }
    }
    
    var method: String {
        return "GET"
    }
    
}



