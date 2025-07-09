import Foundation

/**
 * Availability status for library media items
 * 
 * Represents the various availability states found in German OPAC systems,
 * particularly SISIS-based systems, with appropriate localized descriptions.
 * 
 * - Note: Based on common German library system terminology
 * - Complexity: O(1) for status checking operations
 */
public enum AvailabilityType: String, Codable, CaseIterable, Sendable {
    
    // MARK: - Available States
    
    /// Item is available for immediate checkout at the selected library
    case availableAtLibrary = "ausleihbar"
    
    /// Item is available for reference use only (not for checkout)
    case availableReferenceOnly = "präsenzbestand"
    
    /// Item is available for checkout but currently being processed
    case availableProcessing = "verfügbar_bearbeitung"
    
    // MARK: - Unavailable States
    
    /// Item is currently checked out to another user
    case checkedOut = "entliehen"
    
    /// Item is checked out but due back today
    case dueTodayReturns = "heute_zurück"
    
    /// Item has been reserved/held by other users
    case reserved = "vorgemerkt"
    
    /// Item is on order from another library/location
    case onOrder = "bestellt"
    
    // MARK: - Requestable States
    
    /// Item can be reserved/held for later pickup
    case reservable = "vormerkbar"
    
    /// Item can be ordered from another library location
    case orderable = "bestellbar"
    
    /// Item can be requested from external sources
    case requestable = "anfragbar"
    
    // MARK: - Restricted States
    
    /// Item is not available for checkout
    case notAvailable = "nicht_verfügbar"
    
    /// Item cannot be borrowed
    case notLendable = "nicht_ausleihbar"
    
    /// Item is missing or lost
    case missing = "vermisst"
    
    /// Item is damaged and under repair
    case damaged = "beschädigt"
    
    /// Item is being bound or repaired
    case binding = "einband"
    
    /// Item is in special storage and requires request
    case magazin = "magazin"
    
    // MARK: - Status Information
    
    /// Indicates if the item can potentially be accessed by the user
    public var isAccessible: Bool {
        switch self {
        case .availableAtLibrary, .availableReferenceOnly, .availableProcessing,
             .dueTodayReturns, .reservable, .orderable, .requestable, .magazin:
            return true
        case .checkedOut, .reserved, .onOrder, .notAvailable, .notLendable, 
             .missing, .damaged, .binding:
            return false
        }
    }
    
    /// Indicates if the item is immediately available for checkout
    public var isImmediatelyAvailable: Bool {
        switch self {
        case .availableAtLibrary, .availableProcessing, .dueTodayReturns:
            return true
        default:
            return false
        }
    }
    
    /// Indicates if the user can place a request/reservation for this item
    public var canBeRequested: Bool {
        switch self {
        case .reservable, .orderable, .requestable, .checkedOut, .reserved, .onOrder:
            return true
        default:
            return false
        }
    }
    
    /// User-friendly German description of the availability status
    public var localizedDescription: String {
        switch self {
        case .availableAtLibrary:
            return "Ausleihbar (in der gewählten Bibliothek)"
        case .availableReferenceOnly:
            return "Präsenzbestand (nur zur Einsichtnahme)"
        case .availableProcessing:
            return "Verfügbar (in Bearbeitung)"
        case .checkedOut:
            return "Ausgeliehen"
        case .dueTodayReturns:
            return "Heute zurück erwartet"
        case .reserved:
            return "Vorgemerkt"
        case .onOrder:
            return "Bestellt"
        case .reservable:
            return "Vormerkbar"
        case .orderable:
            return "Bestellbar (aus anderer Bibliothek)"
        case .requestable:
            return "Anfragbar"
        case .notAvailable:
            return "Nicht verfügbar"
        case .notLendable:
            return "Nicht ausleihbar"
        case .missing:
            return "Vermisst"
        case .damaged:
            return "Beschädigt"
        case .binding:
            return "In der Einbandstelle"
        case .magazin:
            return "Magazinbestand (bestellbar)"
        }
    }
    
    /// Short status description for compact display
    public var shortDescription: String {
        switch self {
        case .availableAtLibrary:
            return "Verfügbar"
        case .availableReferenceOnly:
            return "Präsenz"
        case .availableProcessing:
            return "Bearbeitung"
        case .checkedOut:
            return "Entliehen"
        case .dueTodayReturns:
            return "Heute zurück"
        case .reserved:
            return "Vorgemerkt"
        case .onOrder:
            return "Bestellt"
        case .reservable:
            return "Vormerkbar"
        case .orderable:
            return "Bestellbar"
        case .requestable:
            return "Anfragbar"
        case .notAvailable:
            return "Nicht verfügbar"
        case .notLendable:
            return "Nicht ausleihbar"
        case .missing:
            return "Vermisst"
        case .damaged:
            return "Beschädigt"
        case .binding:
            return "Einband"
        case .magazin:
            return "Magazin"
        }
    }
    
    /// Color indicator for UI representation
    public var statusColor: String {
        switch self {
        case .availableAtLibrary, .availableProcessing, .dueTodayReturns:
            return "green"
        case .availableReferenceOnly, .reservable, .orderable, .requestable, .magazin:
            return "yellow"
        case .checkedOut, .reserved, .onOrder:
            return "orange"
        case .notAvailable, .notLendable, .missing, .damaged, .binding:
            return "red"
        }
    }
}

/**
 * Enhanced availability status for individual copies of library items
 * 
 * Represents detailed status and location information for a specific copy
 * of a media item in the library system with enhanced availability typing.
 */
public struct ItemAvailability: Codable, Sendable, Identifiable {
    
    /// Unique identifier for this availability record
    public let id: String
    
    /// Detailed availability status
    public let status: AvailabilityType
    
    /// Physical location of the item (e.g., "Zentralbibliothek, 2. OG")
    public let location: String
    
    /// Call number or shelf location
    public let callNumber: String
    
    /// Due date if the item is currently checked out
    public let dueDate: Date?
    
    /// Number of holds/reservations on this item
    public let reservationCount: Int
    
    /// Additional status information from the library system
    public let statusNote: String?
    
    /// The specific library branch or department
    public let branch: String?
    
    /**
     * Creates a new item availability record
     * 
     * - Parameters:
     *   - id: Unique identifier for this record
     *   - status: Detailed availability status
     *   - location: Physical location of the item
     *   - callNumber: Call number or shelf location
     *   - dueDate: Due date if checked out
     *   - reservationCount: Number of holds on this item
     *   - statusNote: Additional status information
     *   - branch: Specific library branch
     */
    public init(id: String = UUID().uuidString,
                status: AvailabilityType,
                location: String,
                callNumber: String,
                dueDate: Date? = nil,
                reservationCount: Int = 0,
                statusNote: String? = nil,
                branch: String? = nil) {
        self.id = id
        self.status = status
        self.location = location
        self.callNumber = callNumber
        self.dueDate = dueDate
        self.reservationCount = reservationCount
        self.statusNote = statusNote
        self.branch = branch
    }
    
    /// Human-readable availability description with due date if applicable
    public var availabilityDescription: String {
        var description = status.localizedDescription
        
        if let dueDate = dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            description += " (bis \(formatter.string(from: dueDate)))"
        }
        
        return description
    }
    
    /// Detailed status including location and call number
    public var fullDescription: String {
        var components: [String] = []
        
        if let branch = branch, !branch.isEmpty {
            components.append(branch)
        }
        
        if !location.isEmpty {
            components.append(location)
        }
        
        if !callNumber.isEmpty {
            components.append(callNumber)
        }
        
        components.append(availabilityDescription)
        
        if reservationCount > 0 {
            components.append("(\(reservationCount) Vormerkung\(reservationCount == 1 ? "" : "en"))")
        }
        
        return components.joined(separator: " - ")
    }
    
    /// Legacy compatibility property
    public var isAvailable: Bool {
        return status.isImmediatelyAvailable
    }
}

// MARK: - Parsing Helpers

extension AvailabilityType {
    
    /**
     * Parses availability status from German OPAC text
     * 
     * Analyzes common German library system status texts and maps them
     * to appropriate availability types.
     * 
     * - Parameter text: Raw status text from the library system
     * - Returns: Appropriate availability type or nil if unparseable
     */
    public static func parse(from text: String) -> AvailabilityType? {
        let lowercaseText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Exact matches first
        if let directMatch = AvailabilityType(rawValue: lowercaseText) {
            return directMatch
        }
        
        // Pattern matching for common phrases
        // Check negative cases first to avoid false positives
        switch lowercaseText {
        case let text where text.contains("nicht verfügbar"):
            return .notAvailable
        case let text where text.contains("nicht ausleihbar"):
            return .notLendable
        case let text where text.contains("ausleihbar") && text.contains("gewählten bibliothek"):
            return .availableAtLibrary
        case let text where text.contains("ausleihbar"):
            return .availableAtLibrary
        case let text where text.contains("bestellbar") && text.contains("anderer bibliothek"):
            return .orderable
        case let text where text.contains("bestellbar"):
            return .orderable
        case let text where text.contains("präsenzbestand") || text.contains("präsenz"):
            return .availableReferenceOnly
        case let text where text.contains("verfügbar") && text.contains("bearbeitung"):
            return .availableProcessing
        case let text where text.contains("verfügbar"):
            return .availableAtLibrary
        case let text where text.contains("entliehen") || text.contains("ausgeliehen"):
            return .checkedOut
        case let text where text.contains("heute zurück") || text.contains("heute_zurück"):
            return .dueTodayReturns
        case let text where text.contains("vorgemerkt"):
            return .reserved
        case let text where text.contains("bestellt"):
            return .onOrder
        case let text where text.contains("vormerkbar"):
            return .reservable
        case let text where text.contains("anfragbar"):
            return .requestable
        case let text where text.contains("vermisst"):
            return .missing
        case let text where text.contains("beschädigt"):
            return .damaged
        case let text where text.contains("einband"):
            return .binding
        case let text where text.contains("magazin"):
            return .magazin
        default:
            return nil
        }
    }
}
