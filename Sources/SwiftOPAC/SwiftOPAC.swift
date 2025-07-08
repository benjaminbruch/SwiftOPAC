import Foundation

/**
 * SwiftOPAC - A Swift library for accessing OPAC (Online Public Access Catalog) systems.
 * 
 * This library provides a Swift interface for searching and retrieving bibliographic data
 * from OPAC systems, specifically designed for the Dresden Library system.
 * 
 * ## Main Components
 * - `WebOPACService`: Main service for performing searches
 * - `Media`: Data model representing library media items
 * - `Library`: Enumeration of available library branches
 * 
 * ## Usage Example
 * ```swift
 * let service = WebOPACService()
 * service.search(query: "Harry Potter", library: .zentralbibliothek) { result in
 *     switch result {
 *     case .success(let media):
 *         print("Found \(media.count) items")
 *     case .failure(let error):
 *         print("Search failed: \(error)")
 *     }
 * }
 * ```
 */
public struct SwiftOPAC {
    /// Library version information
    public static let version = "1.0.0"
    
    /// Supported OPAC systems
    public static let supportedSystems = ["Dresden WebOPAC"]
}
