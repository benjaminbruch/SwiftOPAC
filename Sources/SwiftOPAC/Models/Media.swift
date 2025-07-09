
import Foundation

/**
 * Represents a media item from an OPAC search result.
 * 
 * This structure contains the core information about a library media item
 * including bibliographic details and media type classification.
 */
public struct Media: Codable, Sendable {
    /// The title of the media item
    public let title: String
    
    /// The author or creator of the media item
    public let author: String
    
    /// The publication year as a string (may be empty if unknown)
    public let year: String
    
    /// The type of media (e.g., "Buch", "CD", "DVD", etc.)
    public let mediaType: String
    
    /// The unique identifier for this media item in the catalog
    public let id: String
    
    /// Basic availability status from search results
    public let isAvailable: Bool
    
    /**
     * Creates a new Media instance with validation.
     * 
     * - Parameters:
     *   - title: The title of the media item
     *   - author: The author or creator
     *   - year: The publication year (will be validated for reasonableness)
     *   - mediaType: The type of media
     *   - id: The unique identifier
     *   - isAvailable: Basic availability status (defaults to true if unknown)
     */
    public init(title: String, author: String, year: String, mediaType: String, id: String, isAvailable: Bool = true) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.author = author.trimmingCharacters(in: .whitespacesAndNewlines)
        self.mediaType = mediaType.trimmingCharacters(in: .whitespacesAndNewlines)
        self.id = id.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isAvailable = isAvailable
        
        // Validate and clean up year
        let cleanYear = year.trimmingCharacters(in: .whitespacesAndNewlines)
        if let yearInt = Int(cleanYear), yearInt >= 1400 && yearInt <= 2030 {
            self.year = cleanYear
        } else {
            self.year = ""
        }
    }
    
    /// Returns true if this media item has valid core data
    public var isValid: Bool {
        return !title.isEmpty && title.count > 1
    }
    
    /// Returns a formatted string representation for debugging
    public var debugDescription: String {
        return "Media(title: '\(title)', author: '\(author)', year: '\(year)', type: '\(mediaType)', id: '\(id)', available: \(isAvailable))"
    }
}
