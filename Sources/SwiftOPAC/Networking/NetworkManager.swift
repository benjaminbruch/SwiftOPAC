import Foundation

final class NetworkManager: Sendable {
    private let urlSession: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpCookieAcceptPolicy = .always
        self.urlSession = URLSession(configuration: configuration)
    }
    
    func fetch(url: URL, completion: @escaping @Sendable (Result<(String, [HTTPCookie]), Error>) -> Void) {
        print("Fetching URL: \(url)")
        
        urlSession.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
                print("Response headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                print("Invalid response data")
                completion(.failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid data"])))
                return
            }
            
            let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
            print("Received \(cookies.count) cookies for URL: \(url)")
            completion(.success((html, cookies)))
        }.resume()
    }
    
    func performRequest(_ request: URLRequest, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response data"])))
                return
            }
            
            completion(.success(html))
        }.resume()
    }
}
