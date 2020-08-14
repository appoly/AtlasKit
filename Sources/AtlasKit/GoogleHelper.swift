//
//  GoogleHelper.swift
//  Boiler Benchmark
//
//  Created by James Wolfe on 14/08/2020.
//  Copyright © 2020 Appoly. All rights reserved.
//



import Foundation


internal class GoogleHelper {
    
    static func extractPostcode(from string: String) -> String? {
        do {
            //Taken from: https://stackoverflow.com/a/164994/4309446
            let regex = try NSRegularExpression(pattern: "([Gg][Ii][Rr] 0[Aa]{2})|((([A-Za-z][0-9]{1,2})|(([A-Za-z][A-Ha-hJ-Yj-y][0-9]{1,2})|(([A-Za-z][0-9][A-Za-z])|([A-Za-z][A-Ha-hJ-Yj-y][0-9][A-Za-z]?))))\\s?[0-9][A-Za-z]{2})")
            let results = regex.matches(in: string, range: NSMakeRange(0, string.count))
            return results.map {
                String(string[Range($0.range, in: string)!])
                }.first?.trimmingCharacters(in: [" ", ","])
        } catch _ {
            return nil
        }
    }
    
    
    static func extractStreetAddress(from string: String) -> String? {
        return string.split(separator: ",").first?.trimmingCharacters(in: [",", " "])
    }
    
    
    static func extractCity(from string: String) -> String? {
        let postcode = extractPostcode(from: string)
        let streetAddress = extractStreetAddress(from: string)
        
        let address = string.replacingOccurrences(of: streetAddress ?? "", with: "").replacingOccurrences(of: postcode ?? "", with: "").trimmingCharacters(in: [",", " "]).split(separator: ",")
        let city = address.count > 0 ? String(address[0]) : nil
        return city?.trimmingCharacters(in: [" ", ","])
    }
    
    
    static func extractState(from string: String) -> String? {
        let postcode = extractPostcode(from: string)
        let streetAddress = extractStreetAddress(from: string)
        
        let address = string.replacingOccurrences(of: streetAddress ?? "", with: "").replacingOccurrences(of: postcode ?? "", with: "").trimmingCharacters(in: [",", " "]).split(separator: ",")
        let state = address.count > 2 ? String(address[1]) : nil
        return state?.trimmingCharacters(in: [" ", ","])
    }
    
    
    static func extractCountry(from string: String) -> String? {
        let postcode = extractPostcode(from: string)
        let streetAddress = extractStreetAddress(from: string)
        
        let address = string.replacingOccurrences(of: streetAddress ?? "", with: "").replacingOccurrences(of: postcode ?? "", with: "").trimmingCharacters(in: [",", " "]).split(separator: ",")
        if(address.count > 1) {
            let country = String(address.count > 2 ? address[2] : address[1])
            return country.trimmingCharacters(in: [" ", ","])
        } else {
            return nil
        }
    }
    
}
