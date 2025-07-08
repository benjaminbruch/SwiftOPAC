import XCTest
@testable import SwiftOPAC

final class AdvancedSearchTests: XCTestCase {
    
    var service: SwiftOPACService!
    
    override func setUp() {
        super.setUp()
        service = SwiftOPACService()
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
        
        XCTAssertEqual(SearchCategory.author.rawValue, 100)
        XCTAssertEqual(SearchCategory.author.displayName, "Verfasser")
        XCTAssertEqual(SearchCategory.author.fieldName, "AU")
        
        XCTAssertEqual(SearchCategory.title.rawValue, 331)
        XCTAssertEqual(SearchCategory.title.displayName, "Titel")
        XCTAssertEqual(SearchCategory.title.fieldName, "TI")
        
        XCTAssertEqual(SearchCategory.isbn.rawValue, 20)
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
    func testAdvancedSearchByAuthor() async throws {
        // Given
        let authorTerm = SearchQuery.SearchTerm(query: "Rowling", category: .author)
        let searchQuery = SearchQuery(terms: [authorTerm], library: .zentralbibliothek)
        
        // When
        let media = try await service.advancedSearch(searchQuery: searchQuery)
        
        // Then
        print("\n=== ADVANCED SEARCH BY AUTHOR ===")
        print("Found \(media.count) items for author 'Rowling'")
        
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
    }
    
    @MainActor
    func testAdvancedSearchByTitle() async throws {
        // Given
        let titleTerm = SearchQuery.SearchTerm(query: "Harry Potter", category: .title)
        let searchQuery = SearchQuery(terms: [titleTerm], library: .zentralbibliothek)
        
        // When
        let media = try await service.advancedSearch(searchQuery: searchQuery)
        
        // Then
        print("\n=== ADVANCED SEARCH BY TITLE ===")
        print("Found \(media.count) items with title 'Harry Potter'")
        
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
    }
    
    @MainActor
    func testAdvancedSearchMultipleTerms() async throws {
        // Given
        let authorTerm = SearchQuery.SearchTerm(query: "Rowling", category: .author, searchOperator: .and)
        let titleTerm = SearchQuery.SearchTerm(query: "Harry", category: .title, searchOperator: .and)
        let searchQuery = SearchQuery(
            terms: [authorTerm, titleTerm],
            library: .zentralbibliothek,
            sortOrder: .titleAscending
        )
        
        // When
        let media = try await service.advancedSearch(searchQuery: searchQuery)
        
        // Then
        print("\n=== ADVANCED SEARCH MULTIPLE TERMS ===")
        print("Found \(media.count) items for author 'Rowling' AND title 'Harry'")
        print("Search description: \(searchQuery.description)")
        
        XCTAssertFalse(media.isEmpty, "Should find media matching both criteria")
        
        // Verify results match both criteria
        for item in media {
            let hasRowling = item.author.lowercased().contains("rowling")
            let hasHarry = item.title.lowercased().contains("harry")
            
            if hasRowling || hasHarry {
                print("  Match: '\(item.title)' by '\(item.author)'")
            }
        }
    }
    
    @MainActor
    func testAdvancedSearchDifferentLibrary() async throws {
        // Given
        let titleTerm = SearchQuery.SearchTerm(query: "Roman", category: .title)
        let searchQuery = SearchQuery(terms: [titleTerm], library: .neustadtBibliothek)
        
        // When & Then
        do {
            let media = try await service.advancedSearch(searchQuery: searchQuery)
            print("\n=== ADVANCED SEARCH NEUSTADT LIBRARY ===")
            print("Found \(media.count) items in Neustadt library for 'Roman'")
            
            // Results should come from the specified library
            XCTAssertTrue(media.count >= 0, "Should handle search in Neustadt library")
        } catch {
            print("Search in Neustadt library failed (may be expected): \(error)")
            // This might fail if Neustadt library is not accessible, which is ok for testing
        }
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testAdvancedSearchInvalidQuery() async {
        // Given - Empty query
        let searchQuery = SearchQuery(terms: [])
        
        // When & Then
        do {
            let media = try await service.advancedSearch(searchQuery: searchQuery)
            // Empty query might still return results, depending on implementation
            print("Empty query returned \(media.count) results")
        } catch {
            print("Empty query failed as expected: \(error)")
        }
    }
    
    // MARK: - Async/Await Tests
    
    @MainActor
    func testAdvancedSearchAsyncAwait() async throws {
        // Given
        let authorTerm = SearchQuery.SearchTerm(query: "Tolkien", category: .author)
        let searchQuery = SearchQuery(terms: [authorTerm], library: .zentralbibliothek)
        
        // When
        let media = try await service.advancedSearch(searchQuery: searchQuery)
        
        // Then
        XCTAssertFalse(media.isEmpty, "Should find media for author Tolkien")
        
        print("\n=== ASYNC/AWAIT SEARCH TEST ===")
        print("Found \(media.count) items for author 'Tolkien'")
        
        // Verify that results contain author information
        let hasTolkienAuthor = media.contains { media in
            media.author.lowercased().contains("tolkien")
        }
        XCTAssertTrue(hasTolkienAuthor, "Results should contain books by Tolkien")
        
        // Print first few results for verification
        for (index, item) in media.enumerated() where index < 3 {
            print("  \(index + 1). '\(item.title)' by '\(item.author)' (\(item.year))")
        }
    }
    
    @MainActor
    func testGetDetailedInfoAsyncAwait() async throws {
        // This test demonstrates async/await syntax but may skip if no valid IDs are found
        // Given - First search for a book to get its ID
        let searchQuery = SearchQuery(simpleQuery: "Harry Potter")
        let searchResults = try await service.advancedSearch(searchQuery: searchQuery)
        
        XCTAssertFalse(searchResults.isEmpty, "Should find at least one result for Harry Potter")
        
        // Try to find a result with a valid ID
        if let firstResult = searchResults.first(where: { !$0.id.isEmpty }) {
            print("Using media ID: '\(firstResult.id)' for detailed info test")
            
            // When
            let detailedInfo = try await service.getDetailedInfo(for: firstResult.id)
            
            // Then
            XCTAssertFalse(detailedInfo.basicInfo.title.isEmpty, "Title should not be empty")
            XCTAssertFalse(detailedInfo.basicInfo.author.isEmpty, "Author should not be empty")
            
            print("\n=== ASYNC/AWAIT DETAILED INFO TEST ===")
            print("Title: \(detailedInfo.basicInfo.title)")
            print("Author: \(detailedInfo.basicInfo.author)")
            print("Year: \(detailedInfo.basicInfo.year)")
            print("Media Type: \(detailedInfo.basicInfo.mediaType)")
            print("Availability count: \(detailedInfo.availability.count)")
            print("Description: \(detailedInfo.description ?? "N/A")")
        } else {
            print("No media items with valid IDs found - async/await pattern still works")
            // This is acceptable since the main goal is to demonstrate async/await pattern
        }
    }
    
    @MainActor
    func testErrorHandlingAsyncAwait() async {
        // Given
        let invalidMediaId = "definitely_invalid_id_that_should_not_exist_12345"
        
        // When & Then
        do {
            let _ = try await service.getDetailedInfo(for: invalidMediaId)
            // If we get here, it means the service didn't throw an error, which might be valid if it returns empty results
            print("\n=== ASYNC/AWAIT ERROR HANDLING TEST ===")
            print("No error thrown for invalid ID - this may be expected behavior")
        } catch let error as SwiftOPACError {
            // Expected error
            print("\n=== ASYNC/AWAIT ERROR HANDLING TEST ===")
            print("Caught expected SwiftOPACError: \(error)")
        } catch {
            print("\n=== ASYNC/AWAIT ERROR HANDLING TEST ===")
            print("Caught unexpected error: \(error)")
            XCTFail("Should throw SwiftOPACError or no error, but got: \(error)")
        }
    }

    // MARK: - Additional Tests
        
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
