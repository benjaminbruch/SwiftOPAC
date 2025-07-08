// WebOPACService.swift

import Foundation

// MARK: - WebOPACService

public class WebOPACService {
    private let networkManager: NetworkManaging
    private let htmlParser: HTMLParsing

    // MARK: - Initialization

    /**
     * Initializes the WebOPACService with dependencies
     */
    public init(networkManager: NetworkManaging, htmlParser: HTMLParsing) {
        self.networkManager = networkManager
        self.htmlParser = htmlParser
    }

    // MARK: - Search Methods

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
                let queryItems = self.createAdvancedSearchQueryItems(searchQuery: searchQuery)
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
            completion(.failure(WebOPACError.invalidMediaId))
            return
        }
        
        guard let url = URL(string: "\(Constants.baseURL)/singleHit.do?id=\(mediaId)") else {
            completion(.failure(WebOPACError.invalidURL))
            return
        }
        
        networkManager.fetch(url: url) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let (html, _)):
                if let detailedInfo = self.htmlParser.parseDetailedMediaInfo(html: html, mediaId: mediaId) {
                    completion(.success(detailedInfo))
                } else {
                    completion(.failure(WebOPACError.parsingFailed))
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
     * - Returns: Array of URL query items for the search request
     */
    private func createAdvancedSearchQueryItems(searchQuery: SearchQuery) -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "methodToCall", value: "submit"),
            URLQueryItem(name: "CSId", value: generateSessionId()),
            URLQueryItem(name: "selectedViewBranchlib", value: String(searchQuery.library.rawValue)),
            URLQueryItem(name: "selectedSearchBranchlib", value: String(searchQuery.library.rawValue))
        ]
        
        // Add search terms with categories
        for (index, term) in searchQuery.terms.enumerated() {
            queryItems.append(URLQueryItem(name: "searchCategories[\(index)]", value: String(term.category.rawValue)))
            queryItems.append(URLQueryItem(name: "searchString[\(index)]", value: term.query))
            
            if index > 0 {
                queryItems.append(URLQueryItem(name: "combinationOperator[\(index)]", value: term.searchOperator.rawValue))
            }
        }
        
        // Add sorting and pagination options
        queryItems.append(URLQueryItem(name: "sortOrder", value: searchQuery.sortOrder.rawValue))
        queryItems.append(URLQueryItem(name: "resultsPerPage", value: String(searchQuery.resultsPerPage)))
        queryItems.append(URLQueryItem(name: "submitSearch", value: "Suchen"))
        queryItems.append(URLQueryItem(name: "callingPage", value: "searchParameters"))
        
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
        guard var urlComponents = URLComponents(string: "\(Constants.baseURL)/search.do") else {
            completion(.failure(WebOPACError.invalidURL))
            return
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            completion(.failure(WebOPACError.invalidURL))
            return
        }
        
        networkManager.fetch(url: url) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let (html, _)):
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