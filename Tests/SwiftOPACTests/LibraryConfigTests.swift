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
    
    
    func testDresdenLibraryConfigDownload() async throws {
        // When
        swiftOPACService = SwiftOPACService(library: .dresdenBibo)
        try await swiftOPACService.loadLibraryConfig()

        // Then
        XCTAssertNotNil(swiftOPACService.libraryConfig)
        XCTAssertEqual(swiftOPACService.libraryConfig?.title, "Städtische Bibliotheken Dresden")
    }

    func testLeipzigLibraryConfigDownload() async throws {
        // When
        swiftOPACService = SwiftOPACService(library: .leipzigBibo)
        try await swiftOPACService.loadLibraryConfig()

        // Then
        XCTAssertNotNil(swiftOPACService.libraryConfig)
        XCTAssertEqual(swiftOPACService.libraryConfig?.title, "Städtische Bibliotheken Leipzig")
    }
}
