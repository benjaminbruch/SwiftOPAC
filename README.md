# SwiftOPAC

A Swift library for accessing SISIS-based OPAC (Online Public Access Catalog) systems, specifically designed for the Dresden Library System. This library provides a modern, type-safe interface for searching library catalogs and retrieving detailed media information.

## Features

- 🔍 **Advanced Search Capabilities**: Multi-field searches with customizable categories and operators
- 📚 **Detailed Media Information**: Comprehensive bibliographic data and availability status
- 🏛️ **Multi-Library Support**: Search across different library branches
- 🛡️ **Type-Safe API**: Full Swift 6 compatibility with sendable types
- ⚡ **Async/Await Ready**: Native async/await support with backward compatibility
- 🧪 **Well-Tested**: Comprehensive unit test coverage

## Installation

### Swift Package Manager

Add SwiftOPAC to your project using Swift Package Manager. In Xcode, go to File > Add Package Dependencies and enter:

```
https://github.com/benjaminbruch/SwiftOPAC.git
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/benjaminbruch/SwiftOPAC.git", from: "1.0.0")
]
```

## Quick Start

### Basic Setup

```swift
import SwiftOPAC

let opacService = SwiftOPACService()
```

### Simple Search

The easiest way to search is using a simple query across all fields:

```swift
// Create a simple search query
let searchQuery = SearchQuery(simpleQuery: "Harry Potter")

// Perform the search using async/await
do {
    let mediaItems = try await opacService.advancedSearch(searchQuery: searchQuery)
    print("Found \(mediaItems.count) items:")
    for media in mediaItems {
        print("- \(media.title) by \(media.author)")
    }
} catch {
    print("Search failed: \(error.localizedDescription)")
}
```

## Advanced Search Examples

### Search by Specific Fields

```swift
// Search for books by a specific author
let authorTerm = SearchQuery.SearchTerm(
    query: "J.K. Rowling",
    category: .author,
    searchOperator: .and
)

let searchQuery = SearchQuery(
    terms: [authorTerm],
    library: .zentralbibliothek,
    sortOrder: .relevance,
    resultsPerPage: 25
)

do {
    let results = try await opacService.advancedSearch(searchQuery: searchQuery)
    // Handle results...
} catch {
    print("Search failed: \(error)")
}
```

### Multi-Field Search with Operators

```swift
// Search for "Harry Potter" in title AND "Rowling" in author
let titleTerm = SearchQuery.SearchTerm(
    query: "Harry Potter",
    category: .title,
    searchOperator: .and
)

let authorTerm = SearchQuery.SearchTerm(
    query: "Rowling",
    category: .author,
    searchOperator: .and  // AND operation with previous term
)

let complexQuery = SearchQuery(
    terms: [titleTerm, authorTerm],
    library: .zentralbibliothek,
    sortOrder: .relevance
)

do {
    let results = try await opacService.advancedSearch(searchQuery: complexQuery)
    print("Found \(results.count) matching items")
} catch {
    print("Error: \(error)")
}
```

### Search with OR Logic

```swift
// Search for items by multiple authors
let firstAuthor = SearchQuery.SearchTerm(
    query: "Stephen King",
    category: .author,
    searchOperator: .and
)

let secondAuthor = SearchQuery.SearchTerm(
    query: "Dean Koontz",
    category: .author,
    searchOperator: .or  // OR operation
)

let multiAuthorQuery = SearchQuery(terms: [firstAuthor, secondAuthor])

do {
    let results = try await opacService.advancedSearch(searchQuery: multiAuthorQuery)
    // Handle results...
} catch {
    print("Search failed: \(error)")
}
```

### ISBN Search

```swift
// Search by ISBN
let isbnTerm = SearchQuery.SearchTerm(
    query: "978-3-16-148410-0",
    category: .isbn,
    searchOperator: .and
)

let isbnQuery = SearchQuery(terms: [isbnTerm])

do {
    let results = try await opacService.advancedSearch(searchQuery: isbnQuery)
    // Handle results...
} catch {
    print("Search failed: \(error)")
}
```

### Publication Year Search

```swift
// Search for books published in a specific year
let yearTerm = SearchQuery.SearchTerm(
    query: "2023",
    category: .year,
    searchOperator: .and
)

let recentBooksQuery = SearchQuery(terms: [yearTerm])

do {
    let results = try await opacService.advancedSearch(searchQuery: recentBooksQuery)
    // Handle results...
} catch {
    print("Search failed: \(error)")
}
```

## Getting Detailed Information

Once you have a media item from search results, you can get detailed information including availability:

```swift
// Assuming you have a media item from search results
let mediaId = "12345" // This comes from the search results

do {
    let detailedMedia = try await opacService.getDetailedInfo(for: mediaId)
    
    print("Title: \(detailedMedia.basicInfo.title)")
    print("Author: \(detailedMedia.basicInfo.author)")
    print("Year: \(detailedMedia.basicInfo.year)")
    print("Media Type: \(detailedMedia.basicInfo.mediaType)")
    print("Description: \(detailedMedia.description ?? "N/A")")
    
    // Check availability
    for availability in detailedMedia.availability {
        print("Location: \(availability.location)")
        print("Available: \(availability.isAvailable ? "Yes" : "No")")
        print("Call Number: \(availability.callNumber)")
        
        if let dueDate = availability.dueDate {
            print("Due back: \(dueDate)")
        }
        
        if availability.reservationCount > 0 {
            print("Reservations: \(availability.reservationCount)")
        }
    }
    
} catch {
    print("Failed to get details: \(error.localizedDescription)")
}
```

## Search Categories

The library supports the following search categories:

| Category | Description | Example Usage |
|----------|-------------|---------------|
| `.all` | Search all fields (default) | General searches |
| `.title` | Search in title field | Book/media titles |
| `.author` | Search by author/creator | Author names |
| `.subject` | Search by subject/topic | Topics, genres |
| `.isbn` | Search by ISBN | ISBN numbers |
| `.publisher` | Search by publisher | Publishing houses |
| `.year` | Search by publication year | Publication dates |
| `.keywords` | Search by keywords | General keywords |
| `.series` | Search by series | Book series |

## Search Operators

Combine multiple search terms using these operators:

| Operator | Description | Usage |
|----------|-------------|-------|
| `.and` | Both terms must match | Default combination |
| `.or` | Either term can match | Alternative matching |
| `.not` | Exclude the term | Negative filtering |

## Libraries

The service supports multiple library branches:

| Library | Description |
|---------|-------------|
| `.zentralbibliothek` | Central Library Dresden (default) |
| `.neustadtBibliothek` | Neustadt Branch Library |

## Error Handling

The library provides comprehensive error handling through the `SwiftOPACError` enum:

```swift
let query = SearchQuery(simpleQuery: "Programming")

do {
    let results = try await opacService.advancedSearch(searchQuery: query)
    // Handle successful results
} catch let error as SwiftOPACError {
    switch error {
    case .networkError(let underlying):
        print("Network error: \(underlying.localizedDescription)")
    case .parsingFailed:
        print("Failed to parse response")
    case .invalidRequest(let message):
        print("Invalid request: \(message)")
    case .sessionExpired:
        print("Session expired, please retry")
    }
} catch {
    print("Unexpected error: \(error.localizedDescription)")
}
```

## Async/Await Support

SwiftOPAC provides native async/await support for modern Swift concurrency:

### Using Async/Await

```swift
import SwiftOPAC

let opacService = SwiftOPACService()

// Simple search with async/await
let searchQuery = SearchQuery(simpleQuery: "Harry Potter")

do {
    let results = try await opacService.advancedSearch(searchQuery: searchQuery)
    print("Found \(results.count) items:")
    
    for media in results {
        print("- \(media.title) by \(media.author)")
    }
    
    // Get detailed information for the first result (if available)
    if let firstMedia = results.first, !firstMedia.id.isEmpty {
        let detailedInfo = try await opacService.getDetailedInfo(for: firstMedia.id)
        print("Detailed info: \(detailedInfo.basicInfo.title)")
        print("Available copies: \(detailedInfo.availability.count)")
    }
    
} catch {
    print("Search failed: \(error)")
}
```

### Complex Search with Async/Await

```swift
// Multi-field search using async/await
let titleTerm = SearchQuery.SearchTerm(
    query: "Harry Potter", 
    category: .title, 
    searchOperator: .and
)

let authorTerm = SearchQuery.SearchTerm(
    query: "Rowling", 
    category: .author, 
    searchOperator: .and
)

let complexQuery = SearchQuery(
    terms: [titleTerm, authorTerm],
    library: .zentralbibliothek,
    sortOrder: .relevance
)

do {
    let results = try await opacService.advancedSearch(searchQuery: complexQuery)
    
    for media in results.prefix(5) {
        print("Title: \(media.title)")
        print("Author: \(media.author)")
        print("Year: \(media.year)")
        print("Type: \(media.mediaType)")
        print("---")
    }
} catch {
    print("Complex search failed: \(error)")
}
```

### Error Handling with Async/Await

```swift
func performSearch() async {
    let query = SearchQuery(simpleQuery: "Programming Books")
    
    do {
        let results = try await opacService.advancedSearch(searchQuery: query)
        
        if results.isEmpty {
            print("No books found")
            return
        }
        
        // Process results...
        for media in results {
            print("Found: \(media.title)")
        }
        
    } catch let error as SwiftOPACError {
        switch error {
        case .networkError(let underlying):
            print("Network issue: \(underlying.localizedDescription)")
        case .parsingFailed:
            print("Could not parse library response")
        case .invalidRequest(let message):
            print("Invalid search: \(message)")
        case .sessionExpired:
            print("Session expired, please retry")
        }
    } catch {
        print("Unexpected error: \(error)")
    }
}
```


```

## Best Practices

### 1. Query Validation

Always validate your search queries before executing:

```swift
let query = SearchQuery(simpleQuery: "")
guard query.isValid else {
    print("Invalid search query")
    return
}
```

### 2. Error Handling

Implement proper error handling for network issues and parsing failures:

```swift
do {
    let results = try await opacService.advancedSearch(searchQuery: query)
    if results.isEmpty {
        print("No results found")
    } else {
        // Process results
        for media in results {
            print("Found: \(media.title)")
        }
    }
} catch {
    // Always handle errors appropriately
    handleError(error)
}
```

### 3. Results Pagination

Control the number of results returned to improve performance:

```swift
let query = SearchQuery(
    simpleQuery: "programming",
    library: .zentralbibliothek,
    sortOrder: .relevance,
    resultsPerPage: 20  // Limit results for better performance
)
```

### 4. Memory Management

The service uses weak references internally to prevent retain cycles, but ensure proper memory management in your usage:

```swift
class SearchViewController {
    private let opacService = SwiftOPACService()
    
    func performSearch() async {
        let query = SearchQuery(simpleQuery: searchText)
        
        do {
            let results = try await opacService.advancedSearch(searchQuery: query)
            await MainActor.run {
                self.handleSearchResults(results)
            }
        } catch {
            await MainActor.run {
                self.handleError(error)
            }
        }
    }
}
```

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.9+
- Xcode 15.0+

## Dependencies

- [SwiftSoup](https://github.com/scinfu/SwiftSoup) - HTML parsing

## Thread Safety

All types in SwiftOPAC conform to `Sendable` and are thread-safe. The service can be used from any queue, and async/await methods are called on the same queue that initiated the request.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or feature requests, please create an issue on GitHub.

---

**Note**: This library is specifically designed for SISIS-based OPAC systems and has been tested with the Dresden Library System. Compatibility with other library systems may vary.
