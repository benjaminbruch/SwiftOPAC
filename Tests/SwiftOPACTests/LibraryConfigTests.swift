import XCTest
@testable import SwiftOPAC

/**
 * Test suite for library configuration download functionality.
 * 
 * This test class validates the ability to download and parse library
 * configurations from the SwiftOPAC service, with specific focus on
 * the Dresden Bibo configuration.
 */
final class LibraryConfigTests: XCTestCase {
    
    // MARK: - Properties
    
    private var swiftOPACService: SwiftOPACService!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        swiftOPACService = SwiftOPACService(library: .dresdenBibo)
    }
    
    override func tearDownWithError() throws {
        swiftOPACService = nil
        try super.tearDownWithError()
    }

    func testLibraryConfigDownload() async throws {
        // When
        try await swiftOPACService.loadLibraryConfig()

        // Then
        XCTAssertNotNil(swiftOPACService.libraryConfig)
        XCTAssertEqual(swiftOPACService.libraryConfig?.title, "Städtische Bibliotheken Dresden")
    }
}
