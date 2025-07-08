import Foundation

/**
 * Availability status for individual copies of library items
 * 
 * Represents the current status and location information
 * for a specific copy of a media item in the library system.
 */
public struct AvailabilityStatus: Codable, Sendable, Identifiable {
    
    /// Unique identifier for this availability record
    public let id: String
    
    /// Whether this copy is currently available for checkout
    public let isAvailable: Bool
    
    /// Physical location of the item (e.g., "Zentralbibliothek, 2. OG")
    public let location: String
    
    /// Call number or shelf location
    public let callNumber: String
    
    /// Due date if the item is currently checked out
    public let dueDate: Date?
    
    /// Number of holds/reservations on this item
    public let reservationCount: Int
    
    /// Additional status information (e.g., "In Bearbeitung", "Vermisst")
    public let statusNote: String?
    
    /**
     * Creates a new availability status
     * 
     * - Parameters:
     *   - id: Unique identifier for this record
     *   - isAvailable: Whether the item is available for checkout
     *   - location: Physical location of the item
     *   - callNumber: Call number or shelf location
     *   - dueDate: Due date if checked out
     *   - reservationCount: Number of holds on this item
     *   - statusNote: Additional status information
     */
    public init(id: String = UUID().uuidString,
                isAvailable: Bool, 
                location: String, 
                callNumber: String, 
                dueDate: Date? = nil, 
                reservationCount: Int = 0,
                statusNote: String? = nil) {
        self.id = id
        self.isAvailable = isAvailable
        self.location = location
        self.callNumber = callNumber
        self.dueDate = dueDate
        self.reservationCount = reservationCount
        self.statusNote = statusNote
    }
    
    /// Human-readable availability description
    public var availabilityDescription: String {
        if isAvailable {
            return "Verfügbar"
        } else if let dueDate = dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "Ausgeliehen bis \(formatter.string(from: dueDate))"
        } else if let note = statusNote {
            return note
        } else {
            return "Nicht verfügbar"
        }
    }
    
    /// Detailed status including location and call number
    public var fullDescription: String {
        var description = "\(location)"
        if !callNumber.isEmpty {
            description += " - \(callNumber)"
        }
        description += " - \(availabilityDescription)"
        
        if reservationCount > 0 {
            description += " (\(reservationCount) Vormerkung\(reservationCount == 1 ? "" : "en"))"
        }
        
        return description
    }
}

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
    public let availability: [AvailabilityStatus]
    
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
                availability: [AvailabilityStatus] = [], 
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
        return availability.filter { $0.isAvailable }.count
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

extension AvailabilityStatus: CustomStringConvertible {
    public var description: String {
        return fullDescription
    }
}
