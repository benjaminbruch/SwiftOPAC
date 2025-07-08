import XCTest
@testable import SwiftOPAC

final class WebOPACErrorTests: XCTestCase {
    
    // MARK: - Error Creation and Basic Properties Tests
    
    func testBasicErrorCreation() {
        let requestError = SwiftOPACError.invalidRequest("Missing parameters")
        XCTAssertEqual(requestError.errorDescription, "Invalid request: Missing parameters")
        
        let networkError = SwiftOPACError.networkError(URLError(.notConnectedToInternet))
        XCTAssertTrue(networkError.errorDescription?.contains("Network error") == true)
        
        let timeoutError = SwiftOPACError.requestTimeout(30.0)
        XCTAssertEqual(timeoutError.errorDescription, "Request timeout after 30.0 seconds")
    }
    
    func testErrorSeverityClassification() {
        // Critical errors
        XCTAssertEqual(SwiftOPACError.internalError(component: "parser", details: "crash").severity, .critical)
        XCTAssertEqual(SwiftOPACError.dataCorruption("invalid checksum").severity, .critical)
        
        // Error level
        XCTAssertEqual(SwiftOPACError.networkError(URLError(.notConnectedToInternet)).severity, .error)
        XCTAssertEqual(SwiftOPACError.sessionError.severity, .error)
        XCTAssertEqual(SwiftOPACError.authenticationFailed.severity, .error)
        
        // Warning level
        XCTAssertEqual(SwiftOPACError.serviceUnavailable.severity, .warning)
        XCTAssertEqual(SwiftOPACError.requestTimeout(30).severity, .warning)
        XCTAssertEqual(SwiftOPACError.rateLimitExceeded(60).severity, .warning)
        
        // Info level
        XCTAssertEqual(SwiftOPACError.invalidRequest("test").severity, .info)
        XCTAssertEqual(SwiftOPACError.noResultsFound.severity, .info)
        XCTAssertEqual(SwiftOPACError.invalidMediaId.severity, .info)
    }
    
    func testErrorCategorization() {
        // Validation errors
        XCTAssertEqual(SwiftOPACError.invalidRequest("test").category, .validation)
        XCTAssertEqual(SwiftOPACError.invalidURL.category, .validation)
        XCTAssertEqual(SwiftOPACError.invalidMediaId.category, .validation)
        
        // Network errors
        XCTAssertEqual(SwiftOPACError.networkError(URLError(.timedOut)).category, .network)
        XCTAssertEqual(SwiftOPACError.requestTimeout(30).category, .network)
        XCTAssertEqual(SwiftOPACError.rateLimitExceeded(nil).category, .network)
        
        // Data errors
        XCTAssertEqual(SwiftOPACError.parsingFailed.category, .data)
        XCTAssertEqual(SwiftOPACError.invalidResponse.category, .data)
        XCTAssertEqual(SwiftOPACError.dataCorruption("test").category, .data)
        
        // Authentication errors
        XCTAssertEqual(SwiftOPACError.authenticationFailed.category, .authentication)
        XCTAssertEqual(SwiftOPACError.sessionExpired.category, .authentication)
        XCTAssertEqual(SwiftOPACError.insufficientPermissions("read").category, .authentication)
        
        // Availability errors
        XCTAssertEqual(SwiftOPACError.serviceUnavailable.category, .availability)
        XCTAssertEqual(SwiftOPACError.libraryUnavailable("test").category, .availability)
        XCTAssertEqual(SwiftOPACError.mediaUnavailable("123").category, .availability)
        
        // Search errors
        XCTAssertEqual(SwiftOPACError.noResultsFound.category, .search)
        XCTAssertEqual(SwiftOPACError.unsupportedSearchCategory("custom").category, .search)
        
        // System errors
        XCTAssertEqual(SwiftOPACError.internalError(component: "test", details: "error").category, .system)
        XCTAssertEqual(SwiftOPACError.unknown("test").category, .system)
    }
    
    // MARK: - Retry Logic Tests
    
    func testRetryableErrors() {
        // Retryable errors
        XCTAssertTrue(SwiftOPACError.networkError(URLError(.timedOut)).isRetryable)
        XCTAssertTrue(SwiftOPACError.serviceUnavailable.isRetryable)
        XCTAssertTrue(SwiftOPACError.requestTimeout(30).isRetryable)
        XCTAssertTrue(SwiftOPACError.rateLimitExceeded(60).isRetryable)
        XCTAssertTrue(SwiftOPACError.sessionExpired.isRetryable)
        
        // Non-retryable errors
        XCTAssertFalse(SwiftOPACError.invalidRequest("test").isRetryable)
        XCTAssertFalse(SwiftOPACError.invalidURL.isRetryable)
        XCTAssertFalse(SwiftOPACError.authenticationFailed.isRetryable)
        XCTAssertFalse(SwiftOPACError.parsingFailed.isRetryable)
        XCTAssertFalse(SwiftOPACError.dataCorruption("test").isRetryable)
    }
    
    func testRetryDelayCalculation() {
        // Rate limit with specific retry after
        let rateLimitError = SwiftOPACError.rateLimitExceeded(120)
        XCTAssertEqual(rateLimitError.suggestedRetryDelay(for: 0), 120.0)
        XCTAssertEqual(rateLimitError.suggestedRetryDelay(for: 5), 120.0) // Should use specified value
        
        // Rate limit without specific retry after (should use fallback)
        let rateLimitErrorNoTime = SwiftOPACError.rateLimitExceeded(nil)
        XCTAssertEqual(rateLimitErrorNoTime.suggestedRetryDelay(for: 0), 5.0)
        XCTAssertEqual(rateLimitErrorNoTime.suggestedRetryDelay(for: 1), 10.0)
        
        // Service unavailable (exponential backoff)
        let serviceError = SwiftOPACError.serviceUnavailable
        XCTAssertEqual(serviceError.suggestedRetryDelay(for: 0), 5.0)
        XCTAssertEqual(serviceError.suggestedRetryDelay(for: 1), 10.0)
        XCTAssertEqual(serviceError.suggestedRetryDelay(for: 2), 20.0)
        XCTAssertEqual(serviceError.suggestedRetryDelay(for: 6), 60.0) // Capped at 60 seconds
        
        // Request timeout (linear increase)
        let timeoutError = SwiftOPACError.requestTimeout(30)
        XCTAssertEqual(timeoutError.suggestedRetryDelay(for: 0), 2.0)
        XCTAssertEqual(timeoutError.suggestedRetryDelay(for: 1), 4.0)
        XCTAssertEqual(timeoutError.suggestedRetryDelay(for: 14), 30.0) // Capped at 30 seconds
        
        // Network error (exponential backoff)
        let networkError = SwiftOPACError.networkError(URLError(.timedOut))
        XCTAssertEqual(networkError.suggestedRetryDelay(for: 0), 1.0)
        XCTAssertEqual(networkError.suggestedRetryDelay(for: 1), 2.0)
        XCTAssertEqual(networkError.suggestedRetryDelay(for: 2), 4.0)
        XCTAssertEqual(networkError.suggestedRetryDelay(for: 5), 20.0) // Capped at 20 seconds
        
        // Session expired (immediate retry)
        let sessionExpiredError = SwiftOPACError.sessionExpired
        XCTAssertEqual(sessionExpiredError.suggestedRetryDelay(for: 0), 1.0)
        XCTAssertEqual(sessionExpiredError.suggestedRetryDelay(for: 5), 1.0)
        
        // Non-retryable error
        let validationError = SwiftOPACError.invalidRequest("test")
        XCTAssertNil(validationError.suggestedRetryDelay(for: 0))
    }
    
    // MARK: - Error Identification Tests
    
    func testErrorIdentifiers() {
        let requestError = SwiftOPACError.invalidRequest("missing parameter")
        let identifier1 = requestError.identifier
        let identifier2 = requestError.identifier
        XCTAssertEqual(identifier1, identifier2) // Should be deterministic
        
        let networkError = SwiftOPACError.networkError(URLError(.notConnectedToInternet))
        XCTAssertTrue(networkError.identifier.contains("network_error"))
        
        let timeoutError = SwiftOPACError.requestTimeout(30.0)
        XCTAssertEqual(timeoutError.identifier, "timeout_30")
        
        let libraryError = SwiftOPACError.libraryUnavailable("dresden")
        XCTAssertTrue(libraryError.identifier.contains("library_unavailable"))
    }
    
    // MARK: - Logging Tests
    
    func testErrorLogging() {
        let error = SwiftOPACError.networkError(URLError(.notConnectedToInternet))
        
        // This should not crash and should output to console
        error.logError(file: "TestFile.swift", function: "testFunction", line: 42)
        
        // Test with different severity levels
        SwiftOPACError.internalError(component: "test", details: "critical issue").logError()
        SwiftOPACError.serviceUnavailable.logError()
        SwiftOPACError.invalidRequest("info level").logError()
    }
    
    // MARK: - Comprehensive Error Message Tests
    
    func testAllErrorDescriptions() {
        let errors: [SwiftOPACError] = [
            .invalidRequest("test message"),
            .invalidURL,
            .invalidMediaId,
            .networkError(URLError(.timedOut)),
            .sessionError,
            .serviceUnavailable,
            .requestTimeout(30),
            .rateLimitExceeded(60),
            .rateLimitExceeded(nil),
            .parsingFailed,
            .invalidResponse,
            .noResultsFound,
            .dataCorruption("checksum failed"),
            .authenticationFailed,
            .sessionExpired,
            .insufficientPermissions("write"),
            .libraryUnavailable("test-lib"),
            .mediaUnavailable("media-123"),
            .unsupportedSearchCategory("custom"),
            .unknown("mystery error"),
            .internalError(component: "parser", details: "null pointer")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error description should not be nil for \(error)")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty for \(error)")
            
            XCTAssertNotNil(error.failureReason, "Failure reason should not be nil for \(error)")
            XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty for \(error)")
            
            XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil for \(error)")
            XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty for \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testErrorMessageCaching() {
        let error = SwiftOPACError.networkError(URLError(.timedOut))
        
        // Measure time for first access (should be slower due to cache miss)
        let firstAccessTime = measureTime {
            _ = error.errorDescription
        }
        
        // Measure time for subsequent access (should be faster due to caching)
        let secondAccessTime = measureTime {
            _ = error.errorDescription
        }
        
        // Second access should be faster or at least not significantly slower
        XCTAssertLessThanOrEqual(secondAccessTime, firstAccessTime * 2.0)
    }
    
    func testMassiveErrorCreation() {
        measure {
            for i in 0..<1000 {
                let error = SwiftOPACError.invalidRequest("Test \(i)")
                _ = error.errorDescription
                _ = error.severity
                _ = error.category
                _ = error.identifier
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func measureTime<T>(operation: () -> T) -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return timeElapsed
    }
}
