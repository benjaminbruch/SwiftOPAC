import Foundation

/**
 * Advanced search query builder based on SISIS patterns
 * 
 * Supports multiple search terms with different categories and operators.
 * This allows for complex queries like "author:Rowling AND title:Harry Potter"
 */
public struct SearchQuery: Codable, Sendable {
    
    /// Search operators for combining terms
    public enum SearchOperator: String, CaseIterable, Codable, Sendable {
        case and = "AND"
        case or = "OR"
        case not = "NOT"
        
        /// Human-readable display name
        public var displayName: String {
            switch self {
            case .and: return "UND"
            case .or: return "ODER" 
            case .not: return "NICHT"
            }
        }
    }
    
    /// Individual search terms with their categories
    public struct SearchTerm: Codable, Sendable {
        public let query: String
        public let category: SearchCategory
        public let searchOperator: SearchOperator
        
        /**
         * Creates a new search term
         * 
         * - Parameters:
         *   - query: The search text
         *   - category: The field to search in (defaults to all fields)
         *   - searchOperator: How to combine with previous terms (defaults to AND)
         */
        public init(query: String, category: SearchCategory = .all, searchOperator: SearchOperator = .and) {
            self.query = query
            self.category = category
            self.searchOperator = searchOperator
        }
    }
    
    // MARK: - Properties
    
    /// The search terms to be executed
    public let terms: [SearchTerm]
    
    /// The library to search in
    public let library: OldLibrary
    
    /// How to sort the results
    public let sortOrder: SortOrder
    
    /// Maximum number of results per page
    public let resultsPerPage: Int
    
    // MARK: - Initializers
    
    /**
     * Creates an advanced search query
     * 
     * - Parameters:
     *   - terms: Array of search terms with categories and operators
     *   - library: Library to search in (defaults to Zentralbibliothek)
     *   - sortOrder: How to sort results (defaults to relevance)
     *   - resultsPerPage: Maximum results per page (defaults to 50)
     */
    public init(terms: [SearchTerm], 
                library: OldLibrary = .zentralbibliothek,
                sortOrder: SortOrder = .relevance,
                resultsPerPage: Int = 50) {
        self.terms = terms
        self.library = library
        self.sortOrder = sortOrder
        self.resultsPerPage = resultsPerPage
    }
    
    /**
     * Convenience initializer for simple queries
     * 
     * Creates a single-term search across all fields
     * 
     * - Parameters:
     *   - simpleQuery: The search text
     *   - library: Library to search in (defaults to Zentralbibliothek)
     *   - sortOrder: How to sort results (defaults to relevance)
     */
    public init(simpleQuery: String, 
                library: OldLibrary = .zentralbibliothek,
                sortOrder: SortOrder = .relevance) {
        let term = SearchTerm(query: simpleQuery, category: .all, searchOperator: .and)
        self.init(terms: [term], library: library, sortOrder: sortOrder)
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if this is a simple single-term search
    public var isSimpleQuery: Bool {
        return terms.count == 1 && terms.first?.category == .all
    }
    
    /// The primary search term (first term's query)
    public var primaryQuery: String {
        return terms.first?.query ?? ""
    }
    
    /// Validates that the search query is properly formed
    public var isValid: Bool {
        return !terms.isEmpty && !terms.allSatisfy { $0.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

// MARK: - CustomStringConvertible

extension SearchQuery: CustomStringConvertible {
    public var description: String {
        let termDescriptions = terms.map { term in
            if term.category == .all {
                return "\"\(term.query)\""
            } else {
                return "\(term.category.fieldName):\"\(term.query)\""
            }
        }
        return termDescriptions.joined(separator: " \(SearchOperator.and.rawValue) ")
    }
}

// MARK: - SearchQuery.SearchOperator Extensions

extension SearchQuery.SearchOperator: CustomStringConvertible {
    public var description: String {
        return displayName
    }
}

// MARK: - SearchQuery.SearchTerm Extensions

extension SearchQuery.SearchTerm: CustomStringConvertible {
    public var description: String {
        if category == .all {
            return "\"\(query)\""
        } else {
            return "\(category.fieldName):\"\(query)\""
        }
    }
}
