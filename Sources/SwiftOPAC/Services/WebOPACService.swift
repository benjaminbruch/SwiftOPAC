import Foundation

public final class WebOPACService: Sendable {
    private let networkManager = NetworkManager()
    private let htmlParser = HTMLParser()

    public init() {}

    public func search(query: String, completion: @escaping @Sendable (Result<[Media], Error>) -> Void) {
        establishSession { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let sessionData):
                self.performSearch(query: query, sessionData: sessionData, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func establishSession(completion: @escaping @Sendable (Result<SessionData, Error>) -> Void) {
        guard let startURL = URL(string: Constants.baseURL) else {
            completion(.failure(NSError(domain: "WebOPACService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid start URL"])))
            return
        }

        networkManager.fetch(url: startURL) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let (html, cookies)):
                if let sessionData = self.htmlParser.extractSessionData(html: html, cookies: cookies) {
                    completion(.success(sessionData))
                } else {
                    completion(.failure(NSError(domain: "WebOPACService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not establish session"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func performSearch(query: String, sessionData: SessionData, completion: @escaping @Sendable (Result<[Media], Error>) -> Void) {
        guard let searchURL = URL(string: Constants.searchURL) else {
            completion(.failure(NSError(domain: "WebOPACService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid search URL"])))
            return
        }

        var urlComponents = URLComponents(url: searchURL, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = createSearchQueryItems(query: query, sessionId: sessionData.sessionId)
        
        guard let finalURL = urlComponents?.url else {
            completion(.failure(NSError(domain: "WebOPACService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not construct search URL"])))
            return
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        
        // Add cookies to the request properly
        if let cookieHeaderValue = HTTPCookie.requestHeaderFields(with: sessionData.cookies)["Cookie"] {
            request.setValue(cookieHeaderValue, forHTTPHeaderField: "Cookie")
            print("Setting cookies: \(cookieHeaderValue)")
        }
        
        // Add additional headers that might be required
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("https://katalog.bibo-dresden.de", forHTTPHeaderField: "Referer")

        networkManager.performRequest(request) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let html):
                print("Search results HTML preview: \(String(html.prefix(1000)))")
                let media = self.htmlParser.parseSearchResults(html: html)
                print("Parsed media count: \(media.count)")
                completion(.success(media))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func createSearchQueryItems(query: String, sessionId: String) -> [URLQueryItem] {
        return [
            URLQueryItem(name: "methodToCall", value: "submit"),
            URLQueryItem(name: "methodToCallParameter", value: "submitSearch"),
            URLQueryItem(name: "submitSearch", value: "Suchen"),
            URLQueryItem(name: "callingPage", value: "searchPreferences"),
            URLQueryItem(name: "numberOfHits", value: "100"),
            URLQueryItem(name: "timeOut", value: "20"),
            URLQueryItem(name: "CSId", value: sessionId),
            URLQueryItem(name: "searchString[0]", value: query),
            URLQueryItem(name: "searchCategories[0]", value: "331"), // Title search
            URLQueryItem(name: "selectedViewBranchlib", value: "0"),
            URLQueryItem(name: "selectedSearchBranchlib", value: "0"),
            // Add some additional parameters that might be needed
            URLQueryItem(name: "searchRestrictionID[0]", value: ""),
            URLQueryItem(name: "searchRestrictionValue1[0]", value: ""),
            URLQueryItem(name: "combinationOperator[0]", value: "AND")
        ]
    }
}
