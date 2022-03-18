//
//  AtlasKitTests.swift
//  AtlasKitTests
//
//  Created by James Wolfe on 18/03/2022.
//



import XCTest
import UIKitExample



class AtlasKitTests: XCTestCase {
    
    // MARK: - Variables
    
    var atlas: AtlasKit?

    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        atlas = .init(.apple)
    }

    override func tearDownWithError() throws {
        atlas = nil
    }
    
    
    
    // MARK: - Tests

    func testSearch() throws {
        let expectation = self.expectation(description: "search_complete")
        var error: Error?
        var places: [AtlasKitPlace]!
        
        atlas?.performSearch("Test", completion: {
            error = $1
            places = $0 ?? []
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 5, handler: nil)
        
        if let error = error {
            throw error
        } else {
            XCTAssertTrue(places.count > 0)
        }
    }

    func testSearchWithDelay() throws {
        let expectation = self.expectation(description: "search_complete")
        var error: Error?
        var places: [AtlasKitPlace]!
        
        atlas?.performSearchWithDelay("Test", delay: 2, completion: {
            error = $1
            places = $0 ?? []
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 7, handler: nil)
        
        if let error = error {
            throw error
        } else {
            XCTAssertTrue(places.count > 0)
        }
    }

}
