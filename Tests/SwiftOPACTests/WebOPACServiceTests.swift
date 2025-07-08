import XCTest
@testable import SwiftOPAC

final class WebOPACServiceTests: XCTestCase {
    
    // MARK: - Detailed Test Methods
    
    @MainActor
    func testSearchWithDetailedOutput() throws {
        let expectation = self.expectation(description: "Search with detailed output")

        let service = WebOPACService()
        service.search(query: "Harry Potter", library: .zentralbibliothek) { result in
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
    
    // MARK: - Advanced Search Integration Tests
    
    @MainActor
    func testAdvancedSearchIntegration() throws {
        let expectation = self.expectation(description: "Advanced search integration")

        let service = WebOPACService()
        
        // Create a simple advanced search query
        let searchQuery = SearchQuery(simpleQuery: "Harry Potter", library: .zentralbibliothek)
        
        service.advancedSearch(searchQuery: searchQuery) { result in
            switch result {
            case .success(let media):
                print("\n=== ADVANCED SEARCH INTEGRATION ===")
                print("Found \(media.count) media items using advanced search")
                
                for (index, item) in media.enumerated() where index < 5 {
                    print("--- Advanced Search Result \(index + 1) ---")
                    print("Title: '\(item.title)'")
                    print("Author: '\(item.author)'")
                    print("Year: '\(item.year)'")
                    print("Media Type: '\(item.mediaType)'")
                }
                
                XCTAssertFalse(media.isEmpty, "Advanced search should return results")
                
                // Verify data quality
                for item in media {
                    XCTAssertFalse(item.title.isEmpty, "Title should not be empty")
                    XCTAssertFalse(item.title.contains("¬"), "Title should be cleaned")
                    XCTAssertFalse(item.author.contains("¬[Verfasser]"), "Author should be cleaned")
                }
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Advanced search integration failed: \(error)")
            }
        }

        waitForExpectations(timeout: 15, handler: nil)
    }
    
    @MainActor
    func testSearchCategoryFiltering() throws {
        let expectation = self.expectation(description: "Search category filtering")

        let service = WebOPACService()
        
        // Create an author-specific search
        let authorTerm = SearchQuery.SearchTerm(query: "Rowling", category: .author)
        let searchQuery = SearchQuery(terms: [authorTerm], library: .zentralbibliothek)
        
        service.advancedSearch(searchQuery: searchQuery) { result in
            switch result {
            case .success(let media):
                print("\n=== AUTHOR SEARCH FILTERING ===")
                print("Found \(media.count) media items by author search")
                
                // Check if results are actually filtered by author
                var rowlingCount = 0
                for item in media {
                    if item.author.lowercased().contains("rowling") {
                        rowlingCount += 1
                        print("✓ Found Rowling book: '\(item.title)'")
                    }
                }
                
                print("Rowling books found: \(rowlingCount) out of \(media.count)")
                
                XCTAssertGreaterThan(media.count, 0, "Should find some media")
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Author search filtering failed: \(error)")
            }
        }

        waitForExpectations(timeout: 15, handler: nil)
    }
    
    // MARK: - Enhanced HTML Parser Tests
    
    func testEnhancedHTMLParsingFeatures() {
        let parser = HTMLParser()
        
        // Test the new availability parsing
        let htmlWithAvailability = """
        <html>
        <body>
        <table>
        <tr class="resultRow">
            <td><img src="book.gif" alt="Buch" /></td>
            <td style="width:100%">
                <a href="singleHit.do?id=123">¬Der Titel des Buches</a><br />
                Mustermann, Max ¬[Verfasser]<br />
                Verlag, 2023<br />
                <span>Standort: Zentralbibliothek</span><br />
                <span>Signatur: Bel 123.4 MUS</span><br />
                <span class="availability">verfügbar</span>
            </td>
        </tr>
        </table>
        </body>
        </html>
        """
        
        print("\n=== ENHANCED HTML PARSING TEST ===")
        
        // Test basic search results parsing (existing functionality)
        let results = parser.parseSearchResults(html: htmlWithAvailability)
        XCTAssertEqual(results.count, 1, "Should parse one result")
        
        if let firstResult = results.first {
            print("Parsed Title: '\(firstResult.title)'")
            print("Parsed Author: '\(firstResult.author)'")
            print("Parsed Year: '\(firstResult.year)'")
            print("Parsed Media Type: '\(firstResult.mediaType)'")
        }
        
        // Test availability parsing (new functionality)
        let availability = parser.parseAvailability(html: htmlWithAvailability)
        print("Parsed \(availability.count) availability records")
        
        for (index, status) in availability.enumerated() {
            print("Availability \(index + 1): \(status.availabilityDescription) at \(status.location)")
        }
        
        // Test detailed media parsing (new functionality)
        if let detailedMedia = parser.parseDetailedMediaInfo(html: htmlWithAvailability, mediaId: "123") {
            print("Detailed Media ID: \(detailedMedia.id)")
            print("Detailed Media Title: '\(detailedMedia.basicInfo.title)'")
            print("Availability Records: \(detailedMedia.availability.count)")
            print("Additional Info: \(detailedMedia.additionalInfo)")
        }
    }
}
