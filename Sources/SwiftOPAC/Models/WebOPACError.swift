import Foundation

/**
 * Errors that can occur in the SwiftOPAC library
 * 
 * Provides structured error handling for various failure scenarios
 * in OPAC operations including network, parsing, and validation errors.
 */
public enum WebOPACError: Error, LocalizedError, Sendable {
    /// Invalid request parameters or configuration
    case invalidRequest(String)
    
    /// Parsing of HTML response failed
    case parsingFailed
    
    /// Network request failed
    case networkError(Error)
    
    /// Invalid or malformed URL
    case invalidURL
    
    /// Session could not be established
    case sessionError
    
    /// Invalid media ID provided
    case invalidMediaId
    
    /// No results found for the search query
    case noResultsFound
    
    /// Service temporarily unavailable
    case serviceUnavailable
    
    /// Invalid response from server
    case invalidResponse
    
    /// Authentication or authorization failed
    case authenticationFailed
    
    /// Unknown error occurred
    case unknown(String)
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .parsingFailed:
            return "Failed to parse server response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL"
        case .sessionError:
            return "Could not establish session with OPAC server"
        case .invalidMediaId:
            return "Invalid media ID provided"
        case .noResultsFound:
            return "No results found for the search query"
        case .serviceUnavailable:
            return "OPAC service is temporarily unavailable"
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed:
            return "Authentication failed"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidRequest(let message):
            return message
        case .parsingFailed:
            return "The server response could not be parsed into the expected format"
        case .networkError:
            return "A network error occurred while communicating with the OPAC server"
        case .invalidURL:
            return "The request URL is malformed or invalid"
        case .sessionError:
            return "The OPAC server did not respond with valid session information"
        case .invalidMediaId:
            return "The provided media ID is empty or invalid"
        case .noResultsFound:
            return "The search query did not match any items in the catalog"
        case .serviceUnavailable:
            return "The OPAC service is currently down for maintenance"
        case .invalidResponse:
            return "The server returned an unexpected response format"
        case .authenticationFailed:
            return "The authentication credentials were rejected by the server"
        case .unknown(let message):
            return message
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidRequest:
            return "Please check your request parameters and try again"
        case .parsingFailed:
            return "Please try again later or contact support if the problem persists"
        case .networkError:
            return "Please check your internet connection and try again"
        case .invalidURL:
            return "Please verify the OPAC server URL configuration"
        case .sessionError:
            return "Please try again later or check if the OPAC service is available"
        case .invalidMediaId:
            return "Please provide a valid media ID"
        case .noResultsFound:
            return "Try using different search terms or broaden your search criteria"
        case .serviceUnavailable:
            return "Please try again later when the service is restored"
        case .invalidResponse:
            return "Please try again later or contact support if the problem persists"
        case .authenticationFailed:
            return "Please check your credentials and try again"
        case .unknown:
            return "Please try again later or contact support if the problem persists"
        }
    }
}
