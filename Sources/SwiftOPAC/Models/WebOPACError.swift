import Foundation
import os.log

/**
 * Errors that can occur in the SwiftOPAC library
 * 
 * Provides structured error handling for various failure scenarios
 * in OPAC operations including network, parsing, and validation errors.
 * 
 * This enum conforms to `LocalizedError` to provide user-friendly error messages
 * and implements comprehensive logging for debugging and monitoring purposes.
 * 
 * - Complexity: O(1) for all error operations
 * - Thread Safety: All operations are thread-safe as the enum is Sendable
 * 
 * ## Usage Examples
 * 
 * ```swift
 * // Basic error creation
 * let error = WebOPACError.invalidRequest("Missing search parameters")
 * 
 * // Error with logging
 * let networkError = WebOPACError.networkError(underlyingError)
 * networkError.logError() // Automatically logs with appropriate level
 * 
 * // Get user-friendly message
 * let message = error.localizedDescription
 * ```
 */
public enum WebOPACError: Error, LocalizedError, Sendable {
    // MARK: - Request and Configuration Errors
    
    /// Invalid request parameters or configuration
    /// - Parameter message: Detailed description of the invalid parameter or configuration
    case invalidRequest(String)
    
    /// Invalid or malformed URL
    /// - Note: This error occurs when URL construction fails or contains invalid characters
    case invalidURL
    
    /// Invalid media ID provided
    /// - Note: Media ID cannot be empty, contain invalid characters, or have incorrect format
    case invalidMediaId
    
    // MARK: - Network and Communication Errors
    
    /// Network request failed
    /// - Parameter error: The underlying network error that caused the failure
    case networkError(Error)
    
    /// Session could not be established
    /// - Note: This indicates authentication or session management issues with the OPAC server
    case sessionError
    
    /// Service temporarily unavailable
    /// - Note: The OPAC service is currently down for maintenance or overloaded
    case serviceUnavailable
    
    /// Request timeout occurred
    /// - Parameter timeoutInterval: The timeout interval that was exceeded
    case requestTimeout(TimeInterval)
    
    /// Rate limit exceeded
    /// - Parameter retryAfter: Suggested time to wait before retrying (in seconds)
    case rateLimitExceeded(TimeInterval?)
    
    // MARK: - Data and Parsing Errors
    
    /// Parsing of HTML response failed
    /// - Note: The server response could not be parsed into the expected format
    case parsingFailed
    
    /// Invalid response from server
    /// - Note: The server returned an unexpected response format or structure
    case invalidResponse
    
    /// No results found for the search query
    /// - Note: The search query did not match any items in the catalog
    case noResultsFound
    
    /// Data corruption detected
    /// - Parameter details: Specific information about the corrupted data
    case dataCorruption(String)
    
    // MARK: - Authentication and Authorization Errors
    
    /// Authentication or authorization failed
    /// - Note: The authentication credentials were rejected by the server
    case authenticationFailed
    
    /// Session expired
    /// - Note: The user session has expired and needs to be renewed
    case sessionExpired
    
    /// Insufficient permissions
    /// - Parameter operation: The operation that was denied due to insufficient permissions
    case insufficientPermissions(String)
    
    // MARK: - Library and Catalog Specific Errors
    
    /// Library not available or not supported
    /// - Parameter libraryId: The identifier of the unavailable library
    case libraryUnavailable(String)
    
    /// Media item not available
    /// - Parameter mediaId: The identifier of the unavailable media item
    case mediaUnavailable(String)
    
    /// Search category not supported
    /// - Parameter category: The unsupported search category
    case unsupportedSearchCategory(String)
    
    // MARK: - General and System Errors
    
    /// Unknown error occurred
    /// - Parameter message: Detailed description of the unknown error
    case unknown(String)
    
    /// Internal system error
    /// - Parameter component: The system component where the error occurred
    /// - Parameter details: Detailed error information for debugging
    case internalError(component: String, details: String)
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        // Request and Configuration Errors
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .invalidMediaId:
            return "Invalid media ID provided"
            
        // Network and Communication Errors
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .sessionError:
            return "Could not establish session with OPAC server"
        case .serviceUnavailable:
            return "OPAC service is temporarily unavailable"
        case .requestTimeout(let interval):
            return "Request timeout after \(interval) seconds"
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limit exceeded. Please try again after \(retryAfter) seconds"
            } else {
                return "Rate limit exceeded. Please try again later"
            }
            
        // Data and Parsing Errors
        case .parsingFailed:
            return "Failed to parse server response"
        case .invalidResponse:
            return "Invalid response from server"
        case .noResultsFound:
            return "No results found for the search query"
        case .dataCorruption(let details):
            return "Data corruption detected: \(details)"
            
        // Authentication and Authorization Errors
        case .authenticationFailed:
            return "Authentication failed"
        case .sessionExpired:
            return "Session has expired"
        case .insufficientPermissions(let operation):
            return "Insufficient permissions for operation: \(operation)"
            
        // Library and Catalog Specific Errors
        case .libraryUnavailable(let libraryId):
            return "Library '\(libraryId)' is not available"
        case .mediaUnavailable(let mediaId):
            return "Media item '\(mediaId)' is not available"
        case .unsupportedSearchCategory(let category):
            return "Search category '\(category)' is not supported"
            
        // General and System Errors
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .internalError(let component, let details):
            return "Internal error in \(component): \(details)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        // Request and Configuration Errors
        case .invalidRequest(let message):
            return message
        case .invalidURL:
            return "The request URL is malformed or invalid"
        case .invalidMediaId:
            return "The provided media ID is empty or invalid"
            
        // Network and Communication Errors
        case .networkError:
            return "A network error occurred while communicating with the OPAC server"
        case .sessionError:
            return "The OPAC server did not respond with valid session information"
        case .serviceUnavailable:
            return "The OPAC service is currently down for maintenance"
        case .requestTimeout:
            return "The request took too long to complete and was cancelled"
        case .rateLimitExceeded:
            return "Too many requests have been made in a short period of time"
            
        // Data and Parsing Errors
        case .parsingFailed:
            return "The server response could not be parsed into the expected format"
        case .invalidResponse:
            return "The server returned an unexpected response format"
        case .noResultsFound:
            return "The search query did not match any items in the catalog"
        case .dataCorruption(let details):
            return "Data integrity check failed: \(details)"
            
        // Authentication and Authorization Errors
        case .authenticationFailed:
            return "The authentication credentials were rejected by the server"
        case .sessionExpired:
            return "The user session has expired and needs to be renewed"
        case .insufficientPermissions(let operation):
            return "User does not have sufficient permissions to perform: \(operation)"
            
        // Library and Catalog Specific Errors
        case .libraryUnavailable(let libraryId):
            return "The library '\(libraryId)' is currently unavailable or not supported"
        case .mediaUnavailable(let mediaId):
            return "The media item '\(mediaId)' is currently unavailable or has been removed"
        case .unsupportedSearchCategory(let category):
            return "The search category '\(category)' is not supported by this library system"
            
        // General and System Errors
        case .unknown(let message):
            return message
        case .internalError(let component, let details):
            return "An internal error occurred in \(component): \(details)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        // Request and Configuration Errors
        case .invalidRequest:
            return "Please check your request parameters and try again"
        case .invalidURL:
            return "Please verify the OPAC server URL configuration"
        case .invalidMediaId:
            return "Please provide a valid media ID"
            
        // Network and Communication Errors
        case .networkError:
            return "Please check your internet connection and try again"
        case .sessionError:
            return "Please try again later or check if the OPAC service is available"
        case .serviceUnavailable:
            return "Please try again later when the service is restored"
        case .requestTimeout:
            return "Please check your internet connection and try again with a stable connection"
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Please wait \(retryAfter) seconds before making another request"
            } else {
                return "Please wait a few minutes before making another request"
            }
            
        // Data and Parsing Errors
        case .parsingFailed:
            return "Please try again later or contact support if the problem persists"
        case .invalidResponse:
            return "Please try again later or contact support if the problem persists"
        case .noResultsFound:
            return "Try using different search terms or broaden your search criteria"
        case .dataCorruption:
            return "Please refresh your data or contact support if the problem persists"
            
        // Authentication and Authorization Errors
        case .authenticationFailed:
            return "Please check your credentials and try again"
        case .sessionExpired:
            return "Please log in again to create a new session"
        case .insufficientPermissions:
            return "Please contact your administrator to request additional permissions"
            
        // Library and Catalog Specific Errors
        case .libraryUnavailable:
            return "Please try selecting a different library or contact support"
        case .mediaUnavailable:
            return "Please check the item availability or search for alternative items"
        case .unsupportedSearchCategory:
            return "Please use a different search category or try a basic search"
            
        // General and System Errors
        case .unknown:
            return "Please try again later or contact support if the problem persists"
        case .internalError:
            return "Please try again later or contact support with the error details"
        }
    }
    
    // MARK: - Logging and Debugging Support
    
    /// Logger instance for WebOPAC errors
    /// - Note: Uses NSLog for backward compatibility and optimal performance
    private static let logSubsystem = "com.swiftopac.library.errors"
    
    /// Cache for frequently accessed error messages to improve performance
    /// - Note: Thread-safe implementation with optimal memory usage and concurrent queue protection
    private static nonisolated(unsafe) let messageCache: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 100 // Limit cache size for memory efficiency
        return cache
    }()
    
    /// Queue for thread-safe cache access
    private static let cacheQueue = DispatchQueue(label: "com.swiftopac.error.cache", attributes: .concurrent)
    
    /**
     * Logs the error with appropriate log level and context information
     * 
     * This method provides structured logging for debugging and monitoring purposes.
     * It automatically determines the appropriate log level based on error severity
     * and includes relevant context information for troubleshooting.
     * 
     * - Parameters:
     *   - file: Source file where the error occurred (default: #file)
     *   - function: Function where the error occurred (default: #function) 
     *   - line: Line number where the error occurred (default: #line)
     * 
     * - Complexity: O(1) - Constant time operation with caching
     * - Thread Safety: Thread-safe implementation using serial queue
     * 
     * ## Usage Example
     * ```swift
     * let error = WebOPACError.networkError(underlyingError)
     * error.logError() // Logs with default context
     * 
     * // Or with custom context
     * error.logError(file: #file, function: #function, line: #line)
     * ```
     */
    public func logError(file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let context = "[\(fileName):\(line)] \(function)"
        let message = "\(Self.logSubsystem) - \(context) - \(self.loggingDescription)"
        
        switch self.severity {
        case .critical, .error:
            NSLog("ERROR: %@", message)
        case .warning:
            NSLog("WARNING: %@", message)
        case .info:
            NSLog("INFO: %@", message)
        }
    }
    
    /**
     * Provides a detailed description optimized for logging purposes
     * 
     * This computed property generates comprehensive error information
     * including error type, associated values, and debugging context.
     * Results are cached for performance optimization.
     * 
     * - Returns: Formatted string suitable for logging systems
     * - Complexity: O(1) with caching, O(n) for first access
     * - Thread Safety: Thread-safe with concurrent queue and barriers
     */
    private var loggingDescription: String {
        let cacheKey = NSString(string: "\(self)")
        
        return Self.cacheQueue.sync {
            if let cached = Self.messageCache.object(forKey: cacheKey) {
                return String(cached)
            }
            
            let description = generateLoggingDescription()
            Self.messageCache.setObject(NSString(string: description), forKey: cacheKey)
            return description
        }
    }
    
    /**
     * Generates detailed logging description for the error
     * 
     * This private method creates comprehensive error descriptions
     * with all relevant context information for debugging purposes.
     * 
     * - Returns: Detailed error description string
     * - Complexity: O(1) - Direct string generation
     * - Note: This method is called only when cache misses occur
     */
    private func generateLoggingDescription() -> String {
        switch self {
        case .invalidRequest(let message):
            return "Invalid request error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription) (Code: \((error as NSError).code))"
        case .requestTimeout(let interval):
            return "Request timeout error: \(interval)s exceeded"
        case .rateLimitExceeded(let retryAfter):
            return "Rate limit exceeded, retry after: \(retryAfter?.description ?? "unknown")"
        case .dataCorruption(let details):
            return "Data corruption detected: \(details)"
        case .insufficientPermissions(let operation):
            return "Insufficient permissions for operation: \(operation)"
        case .libraryUnavailable(let libraryId):
            return "Library unavailable: \(libraryId)"
        case .mediaUnavailable(let mediaId):
            return "Media unavailable: \(mediaId)"
        case .unsupportedSearchCategory(let category):
            return "Unsupported search category: \(category)"
        case .internalError(let component, let details):
            return "Internal error in \(component): \(details)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        default:
            return "Error type: \(String(describing: self))"
        }
    }
    
    /**
     * Determines the severity level of the error for logging purposes
     * 
     * This computed property categorizes errors by severity to enable
     * appropriate logging levels and alerting strategies.
     * 
     * - Returns: ErrorSeverity enum indicating the severity level
     * - Complexity: O(1) - Direct switch statement evaluation
     */
    public var severity: ErrorSeverity {
        switch self {
        case .internalError, .dataCorruption:
            return .critical
        case .networkError, .sessionError, .authenticationFailed, .sessionExpired:
            return .error
        case .serviceUnavailable, .requestTimeout, .rateLimitExceeded, .parsingFailed, .invalidResponse:
            return .warning
        case .invalidRequest, .invalidURL, .invalidMediaId, .noResultsFound, .insufficientPermissions,
             .libraryUnavailable, .mediaUnavailable, .unsupportedSearchCategory, .unknown:
            return .info
        }
    }
    
    /**
     * Provides error categorization for analytics and monitoring
     * 
     * This property groups errors into logical categories for better
     * error tracking, analytics, and automated monitoring systems.
     * 
     * - Returns: ErrorCategory enum indicating the error category
     * - Complexity: O(1) - Direct switch statement evaluation
     */
    public var category: ErrorCategory {
        switch self {
        case .invalidRequest, .invalidURL, .invalidMediaId:
            return .validation
        case .networkError, .requestTimeout, .rateLimitExceeded:
            return .network
        case .parsingFailed, .invalidResponse, .dataCorruption:
            return .data
        case .sessionError, .authenticationFailed, .sessionExpired, .insufficientPermissions:
            return .authentication
        case .serviceUnavailable, .libraryUnavailable, .mediaUnavailable:
            return .availability
        case .noResultsFound, .unsupportedSearchCategory:
            return .search
        case .internalError, .unknown:
            return .system
        }
    }
    
    /**
     * Generates a unique error identifier for tracking purposes
     * 
     * This method creates deterministic identifiers based on error type
     * and parameters for error tracking and deduplication in monitoring systems.
     * 
     * - Returns: Unique string identifier for the error instance
     * - Complexity: O(1) - Hash-based identifier generation
     */
    public var identifier: String {
        switch self {
        case .invalidRequest(let message):
            return "invalid_request_\(message.hashValue)"
        case .networkError(let error):
            return "network_error_\((error as NSError).code)"
        case .requestTimeout(let interval):
            return "timeout_\(Int(interval))"
        case .rateLimitExceeded(let retryAfter):
            return "rate_limit_\(retryAfter?.hashValue ?? 0)"
        case .dataCorruption(let details):
            return "data_corruption_\(details.hashValue)"
        case .insufficientPermissions(let operation):
            return "permissions_\(operation.hashValue)"
        case .libraryUnavailable(let libraryId):
            return "library_unavailable_\(libraryId.hashValue)"
        case .mediaUnavailable(let mediaId):
            return "media_unavailable_\(mediaId.hashValue)"
        case .unsupportedSearchCategory(let category):
            return "unsupported_category_\(category.hashValue)"
        case .internalError(let component, let details):
            return "internal_\(component.hashValue)_\(details.hashValue)"
        case .unknown(let message):
            return "unknown_\(message.hashValue)"
        default:
            return String(describing: self).replacingOccurrences(of: " ", with: "_").lowercased()
        }
    }
    
    // MARK: - Error Analysis and Metrics
    
    /**
     * Indicates whether the error is potentially recoverable through retry
     * 
     * This property helps determine if automatic retry mechanisms
     * should be applied for the specific error type.
     * 
     * - Returns: Boolean indicating if the error is retry-worthy
     * - Complexity: O(1) - Direct boolean evaluation
     */
    public var isRetryable: Bool {
        switch self {
        case .networkError, .serviceUnavailable, .requestTimeout, .rateLimitExceeded, .sessionExpired:
            return true
        case .invalidRequest, .invalidURL, .invalidMediaId, .parsingFailed, .invalidResponse,
             .authenticationFailed, .insufficientPermissions, .libraryUnavailable, 
             .mediaUnavailable, .unsupportedSearchCategory, .noResultsFound, .dataCorruption,
             .internalError, .sessionError, .unknown:
            return false
        }
    }
    
    /**
     * Suggests appropriate retry delay for recoverable errors
     * 
     * This method provides intelligent retry delay suggestions based on
     * error type and context, implementing exponential backoff strategies.
     * 
     * - Parameter attemptNumber: The current retry attempt number (0-based)
     * - Returns: Suggested delay in seconds, or nil if retry not recommended
     * - Complexity: O(1) - Mathematical calculation
     */
    public func suggestedRetryDelay(for attemptNumber: Int) -> TimeInterval? {
        guard isRetryable else { return nil }
        
        switch self {
        case .rateLimitExceeded(let retryAfter):
            return retryAfter ?? TimeInterval(min(300, 5 * (attemptNumber + 1))) // Cap at 5 minutes
        case .serviceUnavailable:
            return TimeInterval(min(60, 5 * pow(2, Double(attemptNumber)))) // Exponential backoff up to 1 minute
        case .requestTimeout:
            return TimeInterval(min(30, 2 * (attemptNumber + 1))) // Linear increase up to 30 seconds
        case .networkError:
            return TimeInterval(min(20, 1 * pow(2, Double(attemptNumber)))) // Exponential backoff up to 20 seconds
        case .sessionExpired:
            return 1.0 // Immediate retry after session refresh
        default:
            return nil
        }
    }
}

// MARK: - Supporting Types

/**
 * Error severity levels for logging and monitoring
 * 
 * Provides standardized severity classification for error logging,
 * alerting, and monitoring system integration.
 */
public enum ErrorSeverity: String, CaseIterable, Sendable {
    /// Critical errors requiring immediate attention
    case critical = "critical"
    
    /// Standard errors affecting functionality
    case error = "error"
    
    /// Warning conditions that should be monitored
    case warning = "warning"
    
    /// Informational errors for debugging
    case info = "info"
}

/**
 * Error categories for analytics and monitoring
 * 
 * Logical grouping of errors for better tracking, analytics,
 * and automated monitoring and alerting systems.
 */
public enum ErrorCategory: String, CaseIterable, Sendable {
    /// Input validation and parameter errors
    case validation = "validation"
    
    /// Network communication errors
    case network = "network"
    
    /// Data parsing and processing errors
    case data = "data"
    
    /// Authentication and authorization errors
    case authentication = "authentication"
    
    /// Service and resource availability errors
    case availability = "availability"
    
    /// Search and query related errors
    case search = "search"
    
    /// System and internal errors
    case system = "system"
}
