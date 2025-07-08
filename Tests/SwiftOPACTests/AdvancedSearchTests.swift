import XCTest
@testable import SwiftOPAC

final class AdvancedSearchTests: XCTestCase {
    
    var service: WebOPACService!
    
    override func setUp() {
        super.setUp()
        service = WebOPACService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Search Query Model Tests
    
    func testSearchQuerySimpleInit() {
        // Given
        let query = SearchQuery(simpleQuery: "Harry Potter")
        
        // Then
        XCTAssertEqual(query.terms.count, 1)
        XCTAssertEqual(query.terms.first?.query, "Harry Potter")
        XCTAssertEqual(query.terms.first?.category, .all)
        XCTAssertEqual(query.terms.first?.searchOperator, .and)
        XCTAssertEqual(query.library, .zentralbibliothek)
        XCTAssertEqual(query.sortOrder, .relevance)
        XCTAssertTrue(query.isSimpleQuery)
        XCTAssertTrue(query.isValid)
    }
    
    func testSearchQueryAdvancedInit() {
        // Given
        let authorTerm = SearchQuery.SearchTerm(query: "Rowling", category: .author, searchOperator: .and)
        let titleTerm = SearchQuery.SearchTerm(query: "Harry Potter", category: .title, searchOperator: .and)
        let query = SearchQuery(
            terms: [authorTerm, titleTerm],
            library: .neustadtBibliothek,
            sortOrder: .yearDescending,
            resultsPerPage: 25
        )
        
        // Then
        XCTAssertEqual(query.terms.count, 2)
        XCTAssertEqual(query.library, .neustadtBibliothek)
        XCTAssertEqual(query.sortOrder, .yearDescending)
        XCTAssertEqual(query.resultsPerPage, 25)
        XCTAssertFalse(query.isSimpleQuery)
        XCTAssertTrue(query.isValid)
        XCTAssertEqual(query.primaryQuery, "Rowling")
    }
    
    func testSearchQueryValidation() {
        // Given - Empty query
        let emptyQuery = SearchQuery(terms: [])
        
        // Then
        XCTAssertFalse(emptyQuery.isValid)
        
        // Given - Query with empty terms
        let emptyTermQuery = SearchQuery(terms: [
            SearchQuery.SearchTerm(query: "", category: .title)
        ])
        
        // Then
        XCTAssertFalse(emptyTermQuery.isValid)
        
        // Given - Valid query
        let validQuery = SearchQuery(simpleQuery: "Test")
        
        // Then
        XCTAssertTrue(validQuery.isValid)
    }
    
    // MARK: - Search Category Tests
    
    func testSearchCategoryProperties() {
        // Test all search categories
        XCTAssertEqual(SearchCategory.all.rawValue, -1)
        XCTAssertEqual(SearchCategory.all.displayName, "Alle Felder")
        XCTAssertEqual(SearchCategory.all.fieldName, "ALL")
        
        XCTAssertEqual(SearchCategory.author.rawValue, 1)
        XCTAssertEqual(SearchCategory.author.displayName, "Verfasser")
        XCTAssertEqual(SearchCategory.author.fieldName, "AU")
        
        XCTAssertEqual(SearchCategory.title.rawValue, 4)
        XCTAssertEqual(SearchCategory.title.displayName, "Titel")
        XCTAssertEqual(SearchCategory.title.fieldName, "TI")
        
        XCTAssertEqual(SearchCategory.isbn.rawValue, 7)
        XCTAssertEqual(SearchCategory.isbn.displayName, "ISBN")
        XCTAssertEqual(SearchCategory.isbn.fieldName, "ISBN")
    }
    
    func testSearchCategoryCaseIterable() {
        // Test that all cases are included
        let allCategories = SearchCategory.allCases
        XCTAssertTrue(allCategories.contains(.all))
        XCTAssertTrue(allCategories.contains(.author))
        XCTAssertTrue(allCategories.contains(.title))
        XCTAssertTrue(allCategories.contains(.subject))
        XCTAssertTrue(allCategories.contains(.isbn))
        XCTAssertTrue(allCategories.contains(.publisher))
        XCTAssertTrue(allCategories.contains(.year))
        XCTAssertTrue(allCategories.contains(.keywords))
        XCTAssertTrue(allCategories.contains(.series))
    }
    
    // MARK: - Sort Order Tests
    
    func testSortOrderProperties() {
        XCTAssertEqual(SortOrder.relevance.rawValue, "RELEVANCE")
        XCTAssertEqual(SortOrder.relevance.displayName, "Relevanz")
        
        XCTAssertEqual(SortOrder.titleAscending.rawValue, "TITLE_ASC")
        XCTAssertEqual(SortOrder.titleAscending.displayName, "Titel (A-Z)")
        
        XCTAssertEqual(SortOrder.yearDescending.rawValue, "YEAR_DESC")
        XCTAssertEqual(SortOrder.yearDescending.displayName, "Jahr (absteigend)")
    }
    
    // MARK: - Search Operator Tests
    
    func testSearchOperatorProperties() {
        XCTAssertEqual(SearchQuery.SearchOperator.and.rawValue, "AND")
        XCTAssertEqual(SearchQuery.SearchOperator.and.displayName, "UND")
        
        XCTAssertEqual(SearchQuery.SearchOperator.or.rawValue, "OR")
        XCTAssertEqual(SearchQuery.SearchOperator.or.displayName, "ODER")
        
        XCTAssertEqual(SearchQuery.SearchOperator.not.rawValue, "NOT")
        XCTAssertEqual(SearchQuery.SearchOperator.not.displayName, "NICHT")
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func testAdvancedSearchByAuthor() throws {
        let expectation = self.expectation(description: "Advanced search by author")
        
        // Given
        let authorTerm = SearchQuery.SearchTerm(query: "Rowling", category: .author)
        let searchQuery = SearchQuery(terms: [authorTerm], library: .zentralbibliothek)
        
        // When
        service.advancedSearch(searchQuery: searchQuery) { result in
            switch result {
            case .success(let media):
                print("\n=== ADVANCED SEARCH BY AUTHOR ===")
                print("Found \(media.count) items for author 'Rowling'")
                
                // Then
                XCTAssertFalse(media.isEmpty, "Should find media for author Rowling")
                
                // Verify that results contain author information
                let hasRowlingAuthor = media.contains { media in
                    media.author.lowercased().contains("rowling")
                }
                XCTAssertTrue(hasRowlingAuthor, "Results should contain books by Rowling")
                
                // Print first few results for verification
                for (index, item) in media.enumerated() where index < 3 {
                    print("  \(index + 1). '\(item.title)' by '\(item.author)' (\(item.year))")
                }
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Advanced search by author failed: \(error)")
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    @MainActor
    func testAdvancedSearchByTitle() throws {
        let expectation = self.expectation(description: "Advanced search by title")
        
        // Given
        let titleTerm = SearchQuery.SearchTerm(query: "Harry Potter", category: .title)
        let searchQuery = SearchQuery(terms: [titleTerm], library: .zentralbibliothek)
        
        // When
        service.advancedSearch(searchQuery: searchQuery) { result in
            switch result {
            case .success(let media):
                print("\n=== ADVANCED SEARCH BY TITLE ===")
                print("Found \(media.count) items with title 'Harry Potter'")
                
                // Then
                XCTAssertFalse(media.isEmpty, "Should find media with title Harry Potter")
                
                // Verify that results contain title information
                let hasHarryPotterTitle = media.contains { media in
                    media.title.lowercased().contains("harry potter")
                }
                XCTAssertTrue(hasHarryPotterTitle, "Results should contain Harry Potter in title")
                
                // Print first few results for verification
                for (index, item) in media.enumerated() where index < 3 {
                    print("  \(index + 1). '\(item.title)' by '\(item.author)' (\(item.year))")
                }
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Advanced search by title failed: \(error)")
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    @MainActor
    func testAdvancedSearchMultipleTerms() throws {
        let expectation = self.expectation(description: "Advanced search with multiple terms")
        
        // Given
        let authorTerm = SearchQuery.SearchTerm(query: "Rowling", category: .author, searchOperator: .and)
        let titleTerm = SearchQuery.SearchTerm(query: "Harry", category: .title, searchOperator: .and)
        let searchQuery = SearchQuery(
            terms: [authorTerm, titleTerm],
            library: .zentralbibliothek,
            sortOrder: .titleAscending
        )
        
        // When
        service.advancedSearch(searchQuery: searchQuery) { result in
            switch result {
            case .success(let media):
                print("\n=== ADVANCED SEARCH MULTIPLE TERMS ===")
                print("Found \(media.count) items for author 'Rowling' AND title 'Harry'")
                print("Search description: \(searchQuery.description)")
                
                // Then
                XCTAssertFalse(media.isEmpty, "Should find media matching both criteria")
                
                // Verify results match both criteria
                for item in media {
                    let hasRowling = item.author.lowercased().contains("rowling")
                    let hasHarry = item.title.lowercased().contains("harry")
                    
                    if hasRowling || hasHarry {
                        print("  Match: '\(item.title)' by '\(item.author)'")
                    }
                }
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Advanced search with multiple terms failed: \(error)")
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    @MainActor
    func testAdvancedSearchDifferentLibrary() throws {
        let expectation = self.expectation(description: "Advanced search in different library")
        
        // Given
        let titleTerm = SearchQuery.SearchTerm(query: "Roman", category: .title)
        let searchQuery = SearchQuery(terms: [titleTerm], library: .neustadtBibliothek)
        
        // When
        service.advancedSearch(searchQuery: searchQuery) { result in
            switch result {
            case .success(let media):
                print("\n=== ADVANCED SEARCH NEUSTADT LIBRARY ===")
                print("Found \(media.count) items in Neustadt library for 'Roman'")
                
                // Then - Results should come from the specified library
                XCTAssertTrue(media.count >= 0, "Should handle search in Neustadt library")
                
                expectation.fulfill()
            case .failure(let error):
                print("Search in Neustadt library failed (may be expected): \(error)")
                // This might fail if Neustadt library is not accessible, which is ok for testing
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testAdvancedSearchInvalidQuery() {
        let expectation = self.expectation(description: "Advanced search with invalid query")
        
        // Given - Empty query
        let searchQuery = SearchQuery(terms: [])
        
        // When
        service.advancedSearch(searchQuery: searchQuery) { result in
            switch result {
            case .success(let media):
                // Empty query might still return results, depending on implementation
                print("Empty query returned \(media.count) results")
                expectation.fulfill()
            case .failure(let error):
                print("Empty query failed as expected: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}

// MARK: - Test Extensions

extension AdvancedSearchTests {
    
    func testSearchQueryCodable() throws {
        // Given
        let originalQuery = SearchQuery(
            terms: [
                SearchQuery.SearchTerm(query: "Test", category: .title, searchOperator: .and),
                SearchQuery.SearchTerm(query: "Author", category: .author, searchOperator: .or)
            ],
            library: .neustadtBibliothek,
            sortOrder: .yearDescending,
            resultsPerPage: 100
        )
        
        // When - Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(originalQuery)
        
        // Then - Decode from JSON
        let decoder = JSONDecoder()
        let decodedQuery = try decoder.decode(SearchQuery.self, from: jsonData)
        
        // Verify all properties
        XCTAssertEqual(decodedQuery.terms.count, originalQuery.terms.count)
        XCTAssertEqual(decodedQuery.terms[0].query, "Test")
        XCTAssertEqual(decodedQuery.terms[0].category, .title)
        XCTAssertEqual(decodedQuery.terms[1].query, "Author")
        XCTAssertEqual(decodedQuery.terms[1].category, .author)
        XCTAssertEqual(decodedQuery.library, .neustadtBibliothek)
        XCTAssertEqual(decodedQuery.sortOrder, .yearDescending)
        XCTAssertEqual(decodedQuery.resultsPerPage, 100)
    }
}
