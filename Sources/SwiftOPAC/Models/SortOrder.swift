import Foundation

/**
 * Sort order options for search results based on SISIS capabilities
 * 
 * These options control how search results are ordered in the response.
 * Different sort criteria can be applied to help users find relevant content.
 */
public enum SortOrder: String, CaseIterable, Codable, Sendable {
    /// Sort by relevance (default)
    case relevance = "RELEVANCE"
    
    /// Sort by title ascending (A-Z)
    case titleAscending = "TITLE_ASC"
    
    /// Sort by title descending (Z-A)
    case titleDescending = "TITLE_DESC"
    
    /// Sort by author ascending (A-Z)
    case authorAscending = "AUTHOR_ASC"
    
    /// Sort by author descending (Z-A)
    case authorDescending = "AUTHOR_DESC"
    
    /// Sort by publication year ascending (oldest first)
    case yearAscending = "YEAR_ASC"
    
    /// Sort by publication year descending (newest first)
    case yearDescending = "YEAR_DESC"
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .relevance: return "Relevanz"
        case .titleAscending: return "Titel (A-Z)"
        case .titleDescending: return "Titel (Z-A)"
        case .authorAscending: return "Autor (A-Z)"
        case .authorDescending: return "Autor (Z-A)"
        case .yearAscending: return "Jahr (aufsteigend)"
        case .yearDescending: return "Jahr (absteigend)"
        }
    }
    
    /// Default sort order for searches
    public static let `default`: SortOrder = .relevance
}

// MARK: - CustomStringConvertible

extension SortOrder: CustomStringConvertible {
    public var description: String {
        return displayName
    }
}
