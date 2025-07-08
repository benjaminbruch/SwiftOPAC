import XCTest
@testable import SwiftOPAC

final class WebOPACServiceTests: XCTestCase {
    @MainActor
    func testSearch() throws {
        let expectation = self.expectation(description: "Search")

        let service = WebOPACService()
        service.search(query: "Harry Potter") { result in
            switch result {
            case .success(let media):
                XCTAssertFalse(media.isEmpty)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Search failed with error: \(error)")
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
}
