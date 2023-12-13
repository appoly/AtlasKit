//
//  GoogleNetworkController.swift
//  AtlasKit
//
//  Created by James Wolfe on 13/08/2020.
//  Copyright © 2020 Appoly. All rights reserved.
//



import Foundation
import MapKit
import Contacts



public class AtlasKit {
    
    // MARK: - Variables
    
    private let datasource: AtlasKitDataSource
    private var searchTimer: Timer?
    private var search: MKLocalSearch?
    
    
    
    // MARK: - Initializers
    
    public init(_ datasource: AtlasKitDataSource) {
        self.datasource = datasource
    }
    
    
    
    // MARK: - Actions
    
    /// Performs a delayed local search with Apple Mapkit (to be used when updating search results based on textfield editingChanged action)
    /// - Parameters:
    ///   - term: Search term
    ///   - delay: How long you wish to delay the serach for
    ///   - completion: Code to be ran when a result is received (Places, Error)
    public func performSearchWithDelay(_ term: String, delay: TimeInterval, completion: @escaping (Result<[AtlasKitPlace], AtlasKitError>) -> Void) {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { [weak self] _ in
            self?.performSearch(term, completion: completion)
        })
    }
    
    
    @available(iOS 15.0.0, *)
    public func performSearchWithDelay(_ term: String, delay: TimeInterval) async throws -> [AtlasKitPlace] {
        searchTimer?.invalidate()
        return try await withUnsafeThrowingContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                self?.searchTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { [weak self] _ in
                    self?.performSearch(term) { continuation.resume(with: $0) }
                })
            }
        }
    }
    
    
    @available(iOS 15.0.0, *)
    public func performSearch(_ term: String) async throws -> [AtlasKitPlace] {
        return try await withUnsafeThrowingContinuation { continuation in
            performSearch(term, completion: { continuation.resume(with: $0) })
        }
    }
    
    
    /// Performs a location search using the specified type given in the initializer
    /// - Parameters:
    ///   - term: Search term
    ///   - completion: Code to be ran when a result is received (Places, Error)
    public func performSearch(_ term: String, completion: @escaping (Result<[AtlasKitPlace], AtlasKitError>) -> Void) {
        switch datasource {
            case .apple:
                performMapKitSearch(term, completion: completion)
            case .google:
                performGooglePlacesSearch(term, completion: completion)
            case .getAddress:
                performGetAddressSearch(term, completion: completion)
            case .custom(let url):
                performCustomAddressSearch(term, url: url, completion: completion)
        }
    }
    
    
    
    // MARK: - Lookup Functions
    
    private func performMapKitSearch(_ term: String, completion: @escaping (Result<[AtlasKitPlace], AtlasKitError>) -> Void) {
        search?.cancel()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = term
        
        search = MKLocalSearch(request: request)
        search?.start(completionHandler: { (response, error) in
            DispatchQueue.main.async { [weak self] in
                guard error == nil, let self = self else {
                    completion(.failure(.generic))
                    return
                }
                
                guard let items = response?.mapItems.filter({ $0.placemark.postalAddress != nil }).map({ $0.placemark }) else {
                    completion(.success([]))
                    return
                }
                
                completion(.success(self.formatResults(items)))
            }
        })
    }
    
    
    /// Cancels all pending searches
    public func cancelSearch() {
        searchTimer?.invalidate()
    }
    
    
    private func performGooglePlacesSearch(_ term: String, completion: @escaping (Result<[AtlasKitPlace], AtlasKitError>) -> Void) {
        guard let apiKey = datasource.apiKey else {
            completion(.failure(.apiKey))
            return
        }
        
        let api: AtlasKitAPI = .googleSearch(term: term, apiKey: apiKey)
        var request = URLRequest(url: api.url)
        request.httpMethod = api.method
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
                completion(.failure(.generic))
                return
            }
            
            guard error == nil, let data = data, let self = self else {
                completion(.failure(.generic))
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                completion(.failure(.generic))
                return
            }
            
            guard let data = json["candidates"] as? [[String: Any]] else {
                completion(.failure(.generic))
                return
            }
            
            completion(.success(self.formatResults(data)))
        }.resume()
    }
    
    
    private func performGetAddressSearch(_ postcode: String, completion: @escaping (Result<[AtlasKitPlace], AtlasKitError>) -> Void) {
        guard let apiKey = datasource.apiKey else {
            completion(.failure(.apiKey))
            return
        }
        
        guard let searchTerm = postcode.trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completion(.failure(.generic))
            return
        }
        
        let api: AtlasKitAPI = .getAddressSearch(term: searchTerm, apiKey: apiKey)
        var request = URLRequest(url: api.url)
        request.httpMethod = api.method
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
                completion(.failure(.generic))
                return
            }
            
            guard error == nil, let data = data, let self = self else {
                completion(.failure(.generic))
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                completion(.failure(.generic))
                return
            }
            
            guard let data = json["addresses"] as? [String] else {
                completion(.failure(.generic))
                return
            }
            
            guard let latitude = json["latitude"] as? Double else {
                completion(.failure(.generic))
                return
            }
            
            guard let longitude = json["longitude"] as? Double else {
                completion(.failure(.generic))
                return
            }
            
            completion(.success(self.formatResults(data, postcode: postcode.uppercased().removingAllWhitespaces, latitude: latitude, longitude: longitude)))
        }.resume()
    }
    
    private func performCustomAddressSearch(_ postcode: String, url: String, completion: @escaping (Result<[AtlasKitPlace], AtlasKitError>) -> Void) {
        
        guard let searchTerm = postcode.trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completion(.failure(.generic))
            return
        }
        
        let api: AtlasKitAPI = .custom(url: url, term: searchTerm)
        var request = URLRequest(url: api.url)
        request.httpMethod = api.method
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
                completion(.failure(.generic))
                return
            }
            
            guard error == nil, let data = data, let self = self else {
                completion(.failure(.generic))
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                completion(.failure(.generic))
                return
            }
            
            guard let suggestions = json["suggestions"] as? [[String: String]] else {
                completion(.failure(.generic))
                return
            }
            
            completion(.success(self.formatResults(suggestions, postcode: postcode.uppercased().removingAllWhitespaces)))
        }.resume()
    }
    
    
    
    // MARK: - Utilities
    
    private func formatResults(_ items: [MKPlacemark]) -> [AtlasKitPlace] {
        return items.map({ AtlasKitPlace(streetAddress: $0.postalAddress!.street, city: $0.postalAddress!.city, postcode: $0.postalAddress!.postalCode, state: $0.postalAddress!.state, country: $0.postalAddress!.country, location: $0.coordinate) }).sorted(by: { $0.formattedAddress.localizedStandardCompare($1.formattedAddress) == .orderedAscending })
    }
    
    
    private func formatResults(_ items: [String], postcode: String, latitude: Double?, longitude: Double?) -> [AtlasKitPlace] {
        return items.map({
            let components = $0.split(separator: ",")
            let address1 = components.indices.contains(0) ? components[0] : ""
            let address2 = components.indices.contains(1) ? components[1] : ""
            var address3 = components.indices.contains(2) ? components[2] : ""
            var address4 = components.indices.contains(3) ? components[3] : ""
            let locality = components.indices.contains(4) ? components[4] : ""
            
            if(address3.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                address3 = locality
            } else if(address4.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                address4 = locality
            }

            let address = ([address1, address2, address3, address4].filter({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }).map({ String($0) }).joined(separator: ", "))
            let city = components.indices.contains(5) ? components[5] : ""
            let county = components.indices.contains(6) ? components[6] : ""
            
            let location = [latitude, longitude].contains(nil) ? nil : CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            return AtlasKitPlace(streetAddress: address, city: String(city), postcode: postcode, state: String(county), country: "United Kingdom", location: location)
        }).sorted(by: { $0.formattedAddress.localizedStandardCompare($1.formattedAddress) == .orderedAscending })
    }
    
    private func formatResults(_ items: [[String: String]], postcode: String) -> [AtlasKitPlace] {
        return items.map({
            let address = $0["address"] ?? ""
            let components = address.split(separator: ",")
            let address1 = components.indices.contains(0) ? components[0] : ""
            let address2 = components.indices.contains(1) ? components[1] : ""
            var address3 = components.indices.contains(2) ? components[2] : ""
            var address4 = components.indices.contains(3) ? components[3] : ""
            let locality = components.indices.contains(4) ? components[4] : ""
            
            if(address3.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                address3 = locality
            } else if(address4.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                address4 = locality
            }
            
            let streetAddtress = ([address1, address2, address3, address4].filter({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }).map({ String($0) }).joined(separator: ", "))
            let city = components.indices.contains(5) ? components[5] : ""
            let county = components.indices.contains(6) ? components[6] : ""
            
            let place = AtlasKitPlace(streetAddress: streetAddtress, city: String(city), postcode: postcode, state: String(county), country: "United Kingdom", location: nil)
            place.getAddressId = $0["id"]
            return place
        }).sorted(by: { $0.formattedAddress.localizedStandardCompare($1.formattedAddress) == .orderedAscending })
    }
        
        
    private func formatResults(_ items: [[String: Any]]) -> [AtlasKitPlace] {
        let addresses = items.map { item -> AtlasKitPlace? in
            
            guard let address = item["formatted_address"] as? String,
            let geometry = item["geometry"] as? [String: Any],
            let location = geometry["location"] as? [String: Any],
            let latitude = location["lat"] as? Double,
            let longitude = location["lng"] as? Double else {
                return nil
            }
            
            return AtlasKitPlace(streetAddress: GoogleHelper.extractStreetAddress(from: address), city: GoogleHelper.extractCity(from: address), postcode: GoogleHelper.extractPostcode(from: address), state: GoogleHelper.extractState(from: address), country: GoogleHelper.extractCountry(from: address), location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }.filter({ $0 != nil && ($0!.formattedAddress.first) != nil }).map { $0! }
        
        return addresses.sorted(by: { $0.formattedAddress.localizedStandardCompare($1.formattedAddress) == .orderedAscending })
    }
    
}



extension String {
    
    var removingAllWhitespaces: Self {
        filter { !$0.isWhitespace }
    }
    
}

