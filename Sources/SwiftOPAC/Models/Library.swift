import Foundation

/**
 * Represents available libraries in the Dresden OPAC system.
 * 
 * This enumeration defines the different library branches that can be searched
 * and used as view contexts for search operations.
 */
public enum Library: Int, CaseIterable, Sendable {
    /// Central Library (Zentralbibliothek)
    case zentralbibliothek = 0
    
    /// Neustadt Library Branch
    case neustadtBibliothek = 1
    
    /// The string value used in API requests
    public var value: String {
        return String(self.rawValue)
    }
    
    /// Human-readable display name for the library
    public var displayName: String {
        switch self {
        case .zentralbibliothek:
            return "Zentralbibliothek"
        case .neustadtBibliothek:
            return "Neustadt"
        }
    }
    
    /// Detailed description of the library location
    public var description: String {
        switch self {
        case .zentralbibliothek:
            return "Zentralbibliothek Dresden - Hauptstandort"
        case .neustadtBibliothek:
            return "Bibliothek Neustadt - Zweigstelle"
        }
    }
    
    /// Default library for searches when none is specified
    public static let `default`: Library = .zentralbibliothek
}

// MARK: - Codable Conformance

extension Library: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        
        guard let library = Library(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid library value: \(rawValue)"
            )
        }
        
        self = library
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

// MARK: - CustomStringConvertible

extension Library: CustomStringConvertible {
    public var stringDescription: String {
        return displayName
    }
}
