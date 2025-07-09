import Foundation

public final class SwiftOPACService: Sendable {
    private let networkManager = NetworkManager()
    private let htmlParser = HTMLParser()
    public let libraryConfig: LibraryConfig

    public init(libraryConfig: LibraryConfig) {
        self.libraryConfig = libraryConfig
    }

    private func establishSession() async throws -> SessionData {
        guard let startURL = URL(string: libraryConfig.baseURL+"/start.do") else {
            throw NSError(domain: "WebOPACService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid start URL"])
        }

        let (html, cookies) = try await networkManager.fetch(url: startURL)
        
        if let sessionData: SessionData = htmlParser.extractSessionData(html: html, cookies: cookies) {
            return sessionData
        } else {
            throw NSError(domain: "WebOPACService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not establish session"])
        }
    }
  
    
    // MARK: - Advanced Search Methods
    
    /**
     * Performs an advanced search with multiple criteria
     * 
     * Based on SISIS multi-field search capabilities, this allows
     * for complex queries with different search categories and operators.
     * 
     * - Parameters:
     *   - searchQuery: Advanced search query with multiple terms and options
     * - Returns: Array of Media items matching the search criteria
     * - Throws: SwiftOPACError or other network/parsing errors
     */
    public func advancedSearch(searchQuery: SearchQuery) async throws -> [Media] {
        let sessionData = try await establishSession()
        
        let queryItems = createAdvancedSearchQueryItems(
            searchQuery: searchQuery, 
            sessionId: sessionData.sessionId
        )
        
        return try await performAdvancedSearch(
            queryItems: queryItems, 
            sessionData: sessionData
        )
    }
    
    /**
     * Get detailed information for a specific media item using SISIS-compatible URL pattern
     * 
     * For SISIS systems, the mediaId contains the complete relative URL path to the detailed view.
     * This approach uses the exact URL structure from the search results.
     * 
     * - Parameter mediaId: The relative URL path from search results (e.g., "/webOPACClient/singleHit.do?...")
     * - Returns: DetailedMedia object with comprehensive information
     * - Throws: SwiftOPACError if mediaId is invalid or parsing fails
     */
    public func getDetailedInfo(for mediaId: String) async throws -> DetailedMedia {
        guard !mediaId.isEmpty else {
            throw SwiftOPACError.invalidRequest("Media ID cannot be empty")
        }
        
        // Build the complete URL from the base URL and the relative path
        let detailedURL: String
        if mediaId.hasPrefix("/webOPACClient/") {
            // Complete relative path - use it directly
            detailedURL = "https://katalog.bibo-dresden.de\(mediaId)"
        } else if mediaId.hasPrefix("singleHit.do") {
            // Relative path without /webOPACClient/ prefix
            detailedURL = "https://katalog.bibo-dresden.de/webOPACClient/\(mediaId)"
        } else {
            // Fallback to position-based approach for legacy IDs
            detailedURL = htmlParser.buildPositionBasedMediaURL(
                baseURL: "https://katalog.bibo-dresden.de/webOPACClient",
                position: 1,
                identifier: mediaId
            )
        }
        
        guard let url = URL(string: detailedURL) else {
            throw SwiftOPACError.invalidRequest("Could not create URL for media ID: \(mediaId)")
        }
        
        let (html, _) = try await networkManager.fetch(url: url)
        
        if let detailedInfo = htmlParser.parseDetailedMediaInfo(html: html, mediaId: mediaId) {
            return detailedInfo
        } else {
            throw SwiftOPACError.parsingFailed
        }
    }

    // MARK: - Advanced Search Helper Methods
    
    /**
     * Creates query items for advanced search based on SISIS patterns
     * 
     * - Parameter searchQuery: The advanced search query configuration
     * - Parameter sessionId: The session identifier from established session
     * - Returns: Array of URL query items for the search request
     */
    private func createAdvancedSearchQueryItems(
        searchQuery: SearchQuery, 
        sessionId: String
    ) -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "methodToCall", value: "submit"),
            URLQueryItem(name: "methodToCallParameter", value: "submitSearch"),
            URLQueryItem(name: "submitSearch", value: "Suchen"),
            URLQueryItem(name: "callingPage", value: "searchPreferences"),
            URLQueryItem(name: "numberOfHits", value: String(searchQuery.resultsPerPage)),
            URLQueryItem(name: "timeOut", value: "20"),
            URLQueryItem(name: "CSId", value: sessionId),
            URLQueryItem(name: "selectedViewBranchlib", value: String(searchQuery.library.rawValue)),
            URLQueryItem(name: "selectedSearchBranchlib", value: String(searchQuery.library.rawValue))
        ]
        
        // Add search terms with categories
        for (index, term) in searchQuery.terms.enumerated() {
            queryItems.append(URLQueryItem(name: "searchCategories[\(index)]", value: String(term.category.rawValue)))
            queryItems.append(URLQueryItem(name: "searchString[\(index)]", value: term.query))
            queryItems.append(URLQueryItem(name: "searchRestrictionID[\(index)]", value: ""))
            queryItems.append(URLQueryItem(name: "searchRestrictionValue1[\(index)]", value: ""))
            
            if index > 0 {
                queryItems.append(URLQueryItem(name: "combinationOperator[\(index)]", value: term.searchOperator.rawValue))
            } else {
                queryItems.append(URLQueryItem(name: "combinationOperator[\(index)]", value: "AND"))
            }
        }
        
        return queryItems
    }
    
    /**
     * Performs the advanced search request
     */
    private func performAdvancedSearch(
        queryItems: [URLQueryItem], 
        sessionData: SessionData
    ) async throws -> [Media] {
        guard var urlComponents = URLComponents(string: Constants.searchURL) else {
            throw SwiftOPACError.invalidRequest("Could not create search URL components")
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw SwiftOPACError.invalidRequest("Could not create search URL from components")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add cookies to the request properly
        if let cookieHeaderValue = HTTPCookie.requestHeaderFields(with: sessionData.cookies)["Cookie"] {
            request.setValue(cookieHeaderValue, forHTTPHeaderField: "Cookie")
        }
        
        // Add additional headers that might be required
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("https://katalog.bibo-dresden.de", forHTTPHeaderField: "Referer")

        let html = try await networkManager.performRequest(request)
        return htmlParser.parseSearchResults(html: html)
    }
    
    /**
     * Generates a session ID for the search request
     * Based on SISIS pattern of using timestamps
     */
    private func generateSessionId() -> String {
        return String(Int(Date().timeIntervalSince1970 * 1000))
    }
    
    // MARK: - Backward Compatibility Methods (Completion Handlers)
    
    /**
     * Performs an advanced search with multiple criteria (completion handler version)
     * 
     * This method is provided for backward compatibility. Use the async/await version for new code.
     * 
     * - Parameters:
     *   - searchQuery: Advanced search query with multiple terms and options
     *   - completion: Completion handler with results or error
     */
    public func advancedSearch(
        searchQuery: SearchQuery, 
        completion: @escaping @Sendable (Result<[Media], Error>) -> Void
    ) {
        Task {
            do {
                let results = try await advancedSearch(searchQuery: searchQuery)
                completion(.success(results))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Get detailed information for a specific media item (completion handler version)
     * 
     * This method is provided for backward compatibility. Use the async/await version for new code.
     * 
     * - Parameters:
     *   - mediaId: The unique identifier of the media item
     *   - completion: Completion handler with detailed info or error
     */
    public func getDetailedInfo(
        for mediaId: String, 
        completion: @escaping @Sendable (Result<DetailedMedia, Error>) -> Void
    ) {
        Task {
            do {
                let detailedInfo = try await getDetailedInfo(for: mediaId)
                completion(.success(detailedInfo))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
