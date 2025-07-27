import Foundation

public final class SwiftOPACService {
    private let networkManager = NetworkManager()
    public let library: Library
    public private(set) var libraryConfig: LibraryConfig?
    
    public init(library: Library) {
        self.library = library
        self.libraryConfig = nil
    }

    /**
     * Loads the library configuration asynchronously and sets the libraryConfig property.
     *
     * - Throws: An error if fetching or decoding the config fails.
     */
    public func loadLibraryConfig() async throws {
        self.libraryConfig = try await fetchLibraryConfig()
    }

    /**
     * Fetches the library configuration from the remote URL defined in the Library enum.
     *
     * - Returns: A LibraryConfig object containing the library configuration.
     * - Throws: An error if fetching or decoding the config fails.
     */
    private func fetchLibraryConfig() async throws -> LibraryConfig {
        let url = URL(string: library.remoteConfigURL)!
        let (data, _) = try await networkManager.fetchData(from: url)
        return try JSONDecoder().decode(LibraryConfig.self, from: data)
    }
}


    
