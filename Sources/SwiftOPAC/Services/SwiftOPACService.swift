import Foundation

public final class SwiftOPACService: Sendable {
    private let networkManager = NetworkManager()
    private let htmlParser = HTMLParser()

    public init() {}

    private func establishSession(completion: @escaping @Sendable (Result<SessionData, Error>) -> Void) {

        guard let startURL = URL(string: Constants.baseURL) else {
            completion(.failure(NSError(domain: "WebOPACService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid start URL"])))
            return
        }

        networkManager.fetch(url: startURL) { [weak self] result in
            guard let self: SwiftOPACService = self else { return }

            switch result {
            case .success(let (html, cookies)):
                if let sessionData: SessionData = self.htmlParser.extractSessionData(html: html, cookies: cookies) {
                    completion(.success(sessionData))
                } else {
                    completion(.failure(NSError(domain: "WebOPACService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not establish session"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
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
     *   - completion: Completion handler with results or error
     */
    public func advancedSearch(
        searchQuery: SearchQuery, 
        completion: @escaping @Sendable (Result<[Media], Error>) -> Void
    ) {
        establishSession { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let sessionData):
                let queryItems = self.createAdvancedSearchQueryItems(
                    searchQuery: searchQuery, 
                    sessionId: sessionData.sessionId
                )
                self.performAdvancedSearch(
                    queryItems: queryItems, 
                    sessionData: sessionData, 
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Get detailed information for a specific media item
     * 
     * Retrieves comprehensive information including availability,
     * detailed description, and additional bibliographic data.
     * 
     * - Parameters:
     *   - mediaId: The unique identifier of the media item
     *   - completion: Completion handler with detailed info or error
     */
    public func getDetailedInfo(
        for mediaId: String, 
        completion: @escaping @Sendable (Result<DetailedMedia, Error>) -> Void
    ) {
        guard !mediaId.isEmpty else {
            completion(.failure(SwiftOPACError.invalidRequest("Media ID cannot be empty")))
            return
        }
        
        guard let url = URL(string: "\(Constants.singleHitURL)?id=\(mediaId)") else {
            completion(.failure(SwiftOPACError.invalidRequest("Could not create URL for media ID: \(mediaId)")))
            return
        }
        
        networkManager.fetch(url: url) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let (html, _)):
                if let detailedInfo = self.htmlParser.parseDetailedMediaInfo(html: html, mediaId: mediaId) {
                    completion(.success(detailedInfo))
                } else {
                    completion(.failure(SwiftOPACError.parsingFailed))
                }
            case .failure(let error):
                completion(.failure(error))
            }
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
        sessionData: SessionData, 
        completion: @escaping @Sendable (Result<[Media], Error>) -> Void
    ) {
        guard var urlComponents = URLComponents(string: Constants.searchURL) else {
            completion(.failure(SwiftOPACError.invalidRequest("Could not create search URL components")))
            return
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            completion(.failure(SwiftOPACError.invalidRequest("Could not create search URL from components")))
            return
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

        networkManager.performRequest(request) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let html):
                let results = self.htmlParser.parseSearchResults(html: html)
                completion(.success(results))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Generates a session ID for the search request
     * Based on SISIS pattern of using timestamps
     */
    private func generateSessionId() -> String {
        return String(Int(Date().timeIntervalSince1970 * 1000))
    }
}
