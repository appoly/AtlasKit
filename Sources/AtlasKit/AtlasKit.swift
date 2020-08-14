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
import Alamofire



public class AtlasKit {
    
    // MARK: - Variables
    
    private let datasource: AtlasKitDataSource
    private let sessionManager = SessionManager()
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
    public func performSearchWithDelay(_ term: String, delay: TimeInterval, completion: @escaping ([AtlasKitPlace]?, AtlasKitError?) -> Void) {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] timer in
            self?.performSearch(term, completion: completion)
        })
    }
    
    
    /// Performs a location search using the specified type given in the initializer
    /// - Parameters:
    ///   - term: Search term
    ///   - completion: Code to be ran when a result is received (Places, Error)
    public func performSearch(_ term: String, completion: @escaping ([AtlasKitPlace]?, AtlasKitError?) -> Void) {
        guard isNetworkAvailable() else {
            completion(nil, .networkUnavailable)
            return
        }
        switch datasource {
            case .apple:
                performMapKitSearch(term, completion: completion)
            case .google:
                performGooglePlacesSearch(term, completion: completion)
        }
    }
    
    
    
    // MARK: - Lookup Functions
    
    private func performMapKitSearch(_ term: String, completion: @escaping ([AtlasKitPlace]?, AtlasKitError?) -> Void) {
        search?.cancel()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = term
        
        search = MKLocalSearch(request: request)
        search?.start(completionHandler: { (response, error) in
            DispatchQueue.main.async { [weak self] in
                guard error == nil else {
                    completion(nil, .generic)
                    return
                }
                
                guard let items = response?.mapItems.filter({ $0.placemark.postalAddress != nil }).map({ $0.placemark }) else {
                    completion([], nil)
                    return
                }
                
                completion(self?.formatResults(items) ?? [], nil)
            }
        })
    }
    
    
    /// Cancels all pending searches
    public func cancelSearch() {
        searchTimer?.invalidate()
    }
    
    
    private func performGooglePlacesSearch(_ term: String, completion: @escaping ([AtlasKitPlace]?, AtlasKitError?) -> Void) {
        let parameters = [
            "key": datasource.apiKey!,
            "inputtype": "textquery",
            "locationbias": "ipbias",
            "fields": "formatted_address,name,geometry",
            "input": term
        ]
        
        let request = sessionManager.request(URL(string: "https://maps.googleapis.com/maps/api/place/findplacefromtext/json")!,
                                             method:  .get,
                                        parameters: parameters,
                                        encoding: URLEncoding.methodDependent,
                                        headers: nil)
        
        request.validate(statusCode: 200..<300).responseJSON { [weak self] (response) in
            switch response.result {
                case .failure(_):
                    completion(nil, .generic)
                case .success(let value):
                    guard let json = value as? [String: Any] else {
                        completion(nil, .generic)
                        return
                    }
                    
                    guard let data = json["candidates"] as? [[String: Any]] else {
                        completion(nil, .generic)
                        return
                    }
                    
                    completion(self?.formatResults(data), nil)
            }
        }
    }
    
    
    
    // MARK: - Utilities
    
    private func formatResults(_ items: [MKPlacemark]) -> [AtlasKitPlace] {
        return items.map({ AtlasKitPlace(streetAddress: $0.postalAddress!.street, city: $0.postalAddress!.city, postcode: $0.postalAddress!.postalCode, state: $0.postalAddress!.state, country: $0.postalAddress!.country, location: $0.coordinate) })
    }
        
        
    private func formatResults(_ items: [[String: Any]]) -> [AtlasKitPlace] {
        return items.map { item -> AtlasKitPlace? in
            
            guard let address = item["formatted_address"] as? String,
            let geometry = item["geometry"] as? [String: Any],
            let location = geometry["location"] as? [String: Any],
            let latitude = location["lat"] as? Double,
            let longitude = location["lng"] as? Double else {
                return nil
            }
            
            return AtlasKitPlace(streetAddress: GoogleHelper.extractStreetAddress(from: address), city: GoogleHelper.extractCity(from: address), postcode: GoogleHelper.extractPostcode(from: address), state: GoogleHelper.extractState(from: address), country: GoogleHelper.extractCountry(from: address), location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }.filter({ $0 != nil && ($0!.formattedAddress.first) != nil }) as! [AtlasKitPlace]
    }
    
    
    private func isNetworkAvailable() -> Bool {
        return NetworkReachabilityManager()!.isReachable
    }
    
}
