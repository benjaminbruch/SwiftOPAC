import Foundation

/**
 * Detailed media information with availability data
 * 
 * Based on SISIS detailed view capabilities, this provides
 * comprehensive information about a library item including
 * availability across multiple copies and locations.
 */
public struct DetailedMedia: Codable, Sendable, Identifiable {
    
    /// Basic media information
    public let basicInfo: Media
    
    /// Detailed description or summary
    public let description: String?
    
    /// Table of contents entries
    public let tableOfContents: [String]
    
    /// Subject headings and topics
    public let subjects: [String]
    
    /// Availability information for all copies
    public let availability: [ItemAvailability]
    
    /// Additional bibliographic information
    public let additionalInfo: [String: String]
    
    /// URLs for cover images
    public let coverImageURLs: [String]
    
    /// Edition information
    public let edition: String?
    
    /// Physical description (pages, format, etc.)
    public let physicalDescription: String?
    
    /// Language of the item
    public let language: String?
    
    /// Notes about the item
    public let notes: [String]
    
    /// Unique identifier from basic info
    public var id: String { basicInfo.id }
    
    /**
     * Creates detailed media information
     * 
     * - Parameters:
     *   - basicInfo: Basic media information
     *   - description: Detailed description
     *   - tableOfContents: Table of contents entries
     *   - subjects: Subject headings
     *   - availability: Availability for all copies
     *   - additionalInfo: Additional bibliographic data
     *   - coverImageURLs: Cover image URLs
     *   - edition: Edition information
     *   - physicalDescription: Physical description
     *   - language: Language of the item
     *   - notes: Additional notes
     */
    public init(basicInfo: Media, 
                description: String? = nil,
                tableOfContents: [String] = [], 
                subjects: [String] = [],
                availability: [ItemAvailability] = [], 
                additionalInfo: [String: String] = [:],
                coverImageURLs: [String] = [],
                edition: String? = nil,
                physicalDescription: String? = nil,
                language: String? = nil,
                notes: [String] = []) {
        self.basicInfo = basicInfo
        self.description = description
        self.tableOfContents = tableOfContents
        self.subjects = subjects
        self.availability = availability
        self.additionalInfo = additionalInfo
        self.coverImageURLs = coverImageURLs
        self.edition = edition
        self.physicalDescription = physicalDescription
        self.language = language
        self.notes = notes
    }
    
    /// Total number of copies in the system
    public var totalCopies: Int {
        return availability.count
    }
    
    /// Number of available copies
    public var availableCopies: Int {
        return availability.filter { $0.status.isImmediatelyAvailable }.count
    }
    
    /// Whether any copy is currently available
    public var hasAvailableCopies: Bool {
        return availableCopies > 0
    }
    
    /// Total number of reservations across all copies
    public var totalReservations: Int {
        return availability.reduce(0) { $0 + $1.reservationCount }
    }
    
    /// Summary of availability across all locations
    public var availabilitySummary: String {
        if hasAvailableCopies {
            return "\(availableCopies) von \(totalCopies) verfügbar"
        } else {
            return "Alle \(totalCopies) Exemplare ausgeliehen"
        }
    }
}

// MARK: - Extensions

extension DetailedMedia {
    /// Detailed string representation of the media item
    public var detailedDescription: String {
        return """
        \(basicInfo.title) by \(basicInfo.author) (\(basicInfo.year))
        \(availabilitySummary)
        Locations: \(availability.map { $0.location }.joined(separator: ", "))
        """
    }
}

extension ItemAvailability: CustomStringConvertible {
    public var description: String {
        return fullDescription
    }
}

// MARK: - Legacy Compatibility

/**
 * Legacy AvailabilityStatus for backward compatibility
 * 
 * @deprecated Use ItemAvailability instead
 */
@available(*, deprecated, message: "Use ItemAvailability instead")
public typealias AvailabilityStatus = ItemAvailability
