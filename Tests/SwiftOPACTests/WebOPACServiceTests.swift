import XCTest
@testable import SwiftOPAC

final class WebOPACServiceTests: XCTestCase {
    
    // MARK: - Detailed Test Methods
    
    @MainActor
    func testSearchWithDetailedOutput() throws {
        let expectation = self.expectation(description: "Search with detailed output")

        let service = WebOPACService()
        service.search(query: "Harry Potter") { result in
            switch result {
            case .success(let media):
                print("\n=== SEARCH RESULTS ===")
                print("Found \(media.count) media items")
                
                for (index, item) in media.enumerated() where index < 10 {
                    print("\n--- Media Item \(index + 1) ---")
                    print("Title: '\(item.title)'")
                    print("Author: '\(item.author)'")
                    print("Year: '\(item.year)'")
                    print("Media Type: '\(item.mediaType)'")
                    print("ID: '\(item.id)'")
                }
                
                XCTAssertFalse(media.isEmpty, "No media items found")
                
                // Check for common data mapping issues
                for item in media {
                    XCTAssertFalse(item.title.isEmpty, "Title should not be empty")
                    
                    // Check if year is valid (4 digits or empty)
                    if !item.year.isEmpty {
                        XCTAssertTrue(item.year.count == 4, "Year should be 4 digits, got: '\(item.year)'")
                        XCTAssertTrue(Int(item.year) != nil, "Year should be numeric, got: '\(item.year)'")
                    }
                    
                    // Check for common parsing errors
                    XCTAssertFalse(item.title.contains("¬"), "Title should not contain ¬ character")
                    XCTAssertFalse(item.author.contains("¬[Verfasser]"), "Author should not contain ¬[Verfasser]")
                }
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Search failed with error: \(error)")
            }
        }

        waitForExpectations(timeout: 15, handler: nil)
    }
    
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
    
    // MARK: - HTML Parser Tests
    
    func testHTMLParserWithSampleData() {
        let parser = HTMLParser()
        
        // Create sample HTML that represents typical OPAC result structure
        let sampleHTML = """
        <html>
        <body>
        <table>
        <tr class="resultRow">
            <td><img src="book.gif" alt="Buch" /></td>
            <td style="width:100%">
                <a href="singleHit.do?id=123">¬Der Titel des Buches</a><br />
                Mustermann, Max ¬[Verfasser]<br />
                Verlag, 2023<br />
                ISBN: 978-3-123-45678-9
            </td>
        </tr>
        </table>
        </body>
        </html>
        """
        
        let results = parser.parseSearchResults(html: sampleHTML)
        
        XCTAssertEqual(results.count, 1, "Should parse one result")
        
        if let firstResult = results.first {
            print("\n=== SAMPLE HTML PARSING TEST ===")
            print("Title: '\(firstResult.title)'")
            print("Author: '\(firstResult.author)'")
            print("Year: '\(firstResult.year)'")
            print("Media Type: '\(firstResult.mediaType)'")
            
            XCTAssertEqual(firstResult.title, "Der Titel des Buches", "Title should be correctly extracted")
            XCTAssertEqual(firstResult.author, "Mustermann, Max", "Author should be correctly extracted")
            XCTAssertEqual(firstResult.year, "2023", "Year should be correctly extracted")
            XCTAssertEqual(firstResult.mediaType, "Buch", "Media type should be correctly extracted")
        }
    }
}
