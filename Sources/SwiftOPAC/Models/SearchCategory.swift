import Foundation

/**
 * Search categories supported by SISIS-based OPAC systems
 * 
 * Based on the SISIS implementation, these categories allow
 * for more targeted searches within the library catalog.
 * Each category corresponds to a specific field in the OPAC database.
 */
public enum SearchCategory: Int, CaseIterable, Codable, Sendable {
    /// Search all fields (default)
    case all = -1
    
    /// Search by author/creator (SISIS code for person/author)
    case author = 100
    
    /// Search by publisher
    case publisher = 412
    
    /// Search by title (SISIS code for title)
    case title = 331
    
    /// Search by subject/topic
    case subject = 650
    
    /// Search by ISBN
    case isbn = 20
    
    /// Search by publication year
    case year = 425
    
    /// Search by keywords
    case keywords = 300
    
    /// Search by series
    case series = 490
    
    /// Human-readable name for the search category
    public var displayName: String {
        switch self {
        case .all: return "Alle Felder"
        case .title: return "Titel"
        case .author: return "Verfasser"
        case .subject: return "Schlagwort"
        case .isbn: return "ISBN"
        case .publisher: return "Verlag"
        case .year: return "Erscheinungsjahr"
        case .keywords: return "Stichwörter"
        case .series: return "Reihe"
        }
    }
    
    /// Field name used in search requests
    public var fieldName: String {
        switch self {
        case .all: return "ALL"
        case .title: return "TI"
        case .author: return "AU"
        case .subject: return "SU"
        case .isbn: return "ISBN"
        case .publisher: return "PU"
        case .year: return "YR"
        case .keywords: return "KW"
        case .series: return "SE"
        }
    }
    
    /// Default category for simple searches
    public static let `default`: SearchCategory = .all
}

// MARK: - CustomStringConvertible

extension SearchCategory: CustomStringConvertible {
    public var description: String {
        return displayName
    }
}
