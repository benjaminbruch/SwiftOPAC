import Foundation

final class NetworkManager: Sendable {
    private let urlSession: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpCookieAcceptPolicy = .always
        self.urlSession = URLSession(configuration: configuration)
    }

    func fetchData(from url: URL) async throws -> (Data, URLResponse) {
        print("Fetching data from URL: \(url)")
        
        let (data, response) = try await urlSession.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response status code: \(httpResponse.statusCode)")
            print("Response headers: \(httpResponse.allHeaderFields)")
        }
        
        return (data, response)
    }
    
    func fetch(url: URL) async throws -> (String, [HTTPCookie]) {
        print("Fetching URL: \(url)")
        
        let (data, response) = try await urlSession.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response status code: \(httpResponse.statusCode)")
            print("Response headers: \(httpResponse.allHeaderFields)")
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            print("Invalid response data")
            throw NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid data"])
        }
        
        let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
        print("Received \(cookies.count) cookies for URL: \(url)")
        return (html, cookies)
    }
    
    func performRequest(_ request: URLRequest) async throws -> String {
        let (data, response) = try await urlSession.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response status code: \(httpResponse.statusCode)")
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response data"])
        }
        
        return html
    }
}
