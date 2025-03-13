//
//  SongTrackerTests.swift
//  SongTrackerTests
//
//  Created by Balint Follinus on 13/03/2025.
//

import Testing
import XCTest
@testable import SongTracker

struct SongTrackerTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

final class SongTrackerTests: XCTestCase {
    func testAPIConnection() {
        let expectation = XCTestExpectation(description: "API call completes")
        
        guard let url = URL(string: Config.apiEndpoint) else {
            XCTFail("Invalid API endpoint URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.apiKey, forHTTPHeaderField: "X-API-Key")
        
        let testPayload = [
            "song": "Test Song",
            "artist": "Test Artist"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testPayload)
            print("Test payload: \(testPayload)")
        } catch {
            XCTFail("Failed to create JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            
            if let error = error {
                XCTFail("API request failed: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                XCTFail("No HTTP response")
                return
            }
            
            print("API Response Status: \(httpResponse.statusCode)")
            
            if let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("API Response Body: \(responseString)")
            }
            
            XCTAssertEqual(httpResponse.statusCode, 200, "Expected 200 OK response")
        }.resume()
        
        wait(for: [expectation], timeout: 10.0)
    }
}
