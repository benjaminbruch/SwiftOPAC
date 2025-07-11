import Foundation
import SwiftSoup

struct SessionData {
    let sessionId: String
    let cookies: [HTTPCookie]
}

final class HTMLParser: Sendable {
    func extractSessionData(html: String, cookies: [HTTPCookie]) -> SessionData? {
        do {
            let doc: Document = try SwiftSoup.parse(html)
            
            // Try to find session ID in hidden input fields
            let sessionIdElement: Element? = try doc.select("input[name=CSId]").first()
            let sessionId = try sessionIdElement?.val()
            
            // If not found in HTML, try to extract from cookies
            let finalSessionId = sessionId ?? extractSessionIdFromCookies(cookies)
            
            guard let validSessionId = finalSessionId else {
                return nil
            }
            
            return SessionData(sessionId: validSessionId, cookies: cookies)
        } catch {
            print("Error parsing session data: \(error)")
            return nil
        }
    }
    
    private func extractSessionIdFromCookies(_ cookies: [HTTPCookie]) -> String? {
        return cookies.first(where: { $0.name == "USERSESSIONID" })?.value
    }
    
    func parseSearchResults(html: String) -> [Media] {
        var media: [Media] = []
        do {
            let doc: Document = try SwiftSoup.parse(html)
            
            // Try multiple selectors for different WebOPAC layouts
            let possibleSelectors = [
                "div.resultRow",
                "tr.resultRow", 
                ".result-item",
                "table.data tr",
                "tbody tr",
                "tr[class*='result']",
                "div[class*='result']",
                ".titleData",
                "tr.titleData"
            ]
            
            var resultRows: Elements?
            
            for selector in possibleSelectors {
                let rows = try doc.select(selector)
                if rows.size() > 0 {
                    resultRows = rows
                    break
                }
            }
            
            guard let rows = resultRows, rows.size() > 0 else {
                print("No search results found")
                return media
            }

            for (_, row) in rows.enumerated() {
                let title = try extractTitle(from: row)
                let author = try extractAuthor(from: row)
                let year = try extractYear(from: row)
                let mediaType = try extractMediaType(from: row)
                let id = try extractId(from: row)
                let availability = try extractBasicAvailability(from: row)
                
                // Only add if we have a valid title and it's not a UI element
                if !title.isEmpty && !isUIElement(title) && title != author {
                    media.append(Media(title: title, author: author, year: year, mediaType: mediaType, id: id, availability: availability))
                    if media.count <= 3 {
                        print("Added media: title='\(title)', author='\(author)', year='\(year)', type='\(mediaType)', id='\(id)', availability=\(availability.rawValue)")
                    }
                }
            }
        } catch {
            print("Error parsing search results: \(error)")
        }
        return media
    }
    
    private func extractTitle(from element: Element) throws -> String {
        // First, try to find the main data cell (should be the second td, or td[style*="width:100%"])
        let cells = try element.select("td")
        guard cells.size() > 1 else { return "" }
        
        let mainCell = try element.select("td[style*='width:100%']").first() ?? 
                      cells.get(1)
        
        // Look for the title link in the main cell
        if let titleLink = try mainCell.select("a[href*='singleHit.do']").first() {
            let title = try titleLink.text().trimmingCharacters(in: .whitespacesAndNewlines)
            // Remove the special character ¬ if present at the beginning
            let cleanTitle = title.hasPrefix("¬") ? String(title.dropFirst()) : title
            if !cleanTitle.isEmpty && !isUIElement(cleanTitle) {
                return cleanTitle
            }
        }
        
        return ""
    }
    
    private func extractAuthor(from element: Element) throws -> String {
        // Get the main data cell - following SISIS structure more closely
        let cells = try element.select("td")
        guard cells.size() > 1 else { return "" }
        
        // Get the main content cell (typically the second cell or one with width 100%)
        let mainCell = try element.select("td[style*='width:100%']").first() ?? 
                      cells.get(1)
        
        // Parse the cell content similar to the Java SISIS implementation
        let cellHTML = try mainCell.html()
        
        // Split by various break tags
        var lines = cellHTML.components(separatedBy: "<br />")
        if lines.count == 1 {
            lines = cellHTML.components(separatedBy: "<br/>")
        }
        if lines.count == 1 {
            lines = cellHTML.components(separatedBy: "<br>")
        }
        
        // First try to find explicit author markers like ¬[Verfasser] or [Verfasser]
        for line in lines {
            if line.contains("¬[Verfasser]") || line.contains("[Verfasser]") {
                // Extract the text part and remove the ¬[Verfasser] part
                let cleanLine = line.replacingOccurrences(of: "¬[Verfasser]", with: "")
                                   .replacingOccurrences(of: "[Verfasser]", with: "")
                                   .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                // Remove any remaining HTML tags
                if let doc = try? SwiftSoup.parse(cleanLine) {
                    let text = try doc.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                              .replacingOccurrences(of: "¬", with: "")
                    if !text.isEmpty && isValidAuthorName(text) {
                        return text
                    }
                }
            }
        }
        
        // Alternative approach: Look for structured content similar to Java implementation
        // Check for patterns that typically contain author information
        for line in lines {
            // Skip lines with links (likely titles) and empty lines
            if line.contains("href") || line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                continue
            }
            
            // Parse the line to extract text
            if let doc = try? SwiftSoup.parse(line) {
                let text = try doc.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                        .replacingOccurrences(of: "¬", with: "")
                
                // Check if this looks like a valid author name
                if isValidAuthorName(text) && !isAvailabilityText(text) {
                    return text
                }
            }
        }
        
        return ""
    }
    
    /// Checks if text is likely availability status information
    private func isAvailabilityText(_ text: String) -> Bool {
        let lowercaseText = text.lowercased()
        let availabilityKeywords = [
            "verfügbar", "ausleihbar", "entliehen", "vorgemerkt", 
            "bestellt", "vormerkbar", "bestellbar", "nicht verfügbar",
            "nicht ausleihbar", "status", "exemplar", "heute zurück"
        ]
        
        return availabilityKeywords.contains { lowercaseText.contains($0) }
    }
    
    /// Validates if a string looks like a valid author name
    private func isValidAuthorName(_ text: String) -> Bool {
        let cleanText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // Must not be empty and have reasonable length
        guard !cleanText.isEmpty && cleanText.count >= 3 && cleanText.count <= 100 else {
            return false
        }
        
        // Check for invalid patterns that indicate this is not an author
        let invalidPatterns = [
            "¬[Komponist",
            "¬[Dirigent",
            "[Komponist",
            "[Dirigent",
            "verfügbar",           // Availability status
            "ausleihbar",          // Availability status
            "entliehen",           // Availability status
            "vorgemerkt",          // Availability status
            "bestellt",            // Availability status
            "vormerkbar",          // Availability status
            "bestellbar",          // Availability status
            "ausleihbar",          // Availability status
            "nicht verfügbar",     // Availability status
            "nicht ausleihbar",    // Availability status
            "heute zurück",        // Availability status
            "heute",               // Common in availability texts
            "zurück",              // Common in availability texts
            "ISBN",
            "ISSN",
            "http",
            "www.",
            "<",
            ">",
            "/",
            "BS",  // Bibliotheks-Systematik
            "PS4",
            "PS5",
            "Xbox",
            "Nintendo",
            "CD ",
            "DVD",
            "BD ",
            "LP ",
            "TR ",
            "Kinder",
            "blau",
            "Spiele",
            "Freizeit",
            "Signatur",            // Call number
            "Standort",            // Location
            "Zweigstelle",         // Branch
            "Status",              // Status
            "Mediennummer",        // Media number
            "Exemplar",            // Copy
            "Auflage",             // Edition
            "Seiten",              // Pages
            "ISBN-10",
            "ISBN-13",
            "EAN",
            "Barcode"
        ]
        
        // Check if text contains any invalid patterns
        let lowercaseText = cleanText.lowercased()
        for pattern in invalidPatterns {
            if lowercaseText.contains(pattern.lowercased()) {
                return false
            }
        }
        
        // Check if it's just numbers, dots, dashes (probably a classification)
        if cleanText.allSatisfy({ $0.isNumber || $0.isWhitespace || $0 == "." || $0 == "-" }) {
            return false
        }
        
        // Check for UI keywords
        if isUIElement(cleanText) {
            return false
        }
        
        // Valid author names typically contain letters and may have commas, spaces, dots
        let hasLetters = cleanText.contains { $0.isLetter }
        if !hasLetters {
            return false
        }
        
        // Additional check: reject single words that look like system text
        let words = cleanText.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        if words.count == 1 && words.first?.count ?? 0 < 3 {
            return false
        }
        
        // Check for common non-author terms
        let nonAuthorTerms = ["status", "exemplar", "verfügbar", "ausleihbar", 
                             "entliehen", "vorgemerkt", "bestellt", "signatur",
                             "standort", "mediennummer"]
        if nonAuthorTerms.contains(lowercaseText) {
            return false
        }
        
        return true
    }
    
    private func extractYear(from element: Element) throws -> String {
        // Get the main data cell
        let cells = try element.select("td")
        guard cells.size() > 1 else { return "" }
        
        let mainCell = try element.select("td[style*='width:100%']").first() ?? 
                      cells.get(1)
        
        let cellHTML = try mainCell.html()
        let lines = cellHTML.components(separatedBy: "<br />")
        
        // Look for year patterns in all lines, but prioritize realistic years
        var foundYears: [String] = []
        
        for line in lines {
            // Remove HTML tags first
            let cleanLine: String
            if let doc = try? SwiftSoup.parse(line),
               let text = try? doc.text() {
                cleanLine = text
            } else {
                cleanLine = line
            }
            
            // Look for year patterns: 2024, [2024], c2024, ©2024, etc.
            let yearPatterns = [
                #"(?:^|\s|\[|c|©|, )([12]\d{3})(?:\]|\.|\s|$|,)"#,  // Standard 4-digit years
                #"\[([12]\d{3})\]"#,                                  // Bracketed years
                #"([12]\d{3})"#                                       // Any 4-digit number starting with 1 or 2
            ]
            
            for pattern in yearPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: cleanLine, range: NSRange(cleanLine.startIndex..., in: cleanLine)) {
                    let yearRange = Range(match.range(at: 1), in: cleanLine)!
                    let year = String(cleanLine[yearRange])
                    
                    // Validate year is reasonable (between 1800 and current year + 2)
                    if let yearInt = Int(year), yearInt >= 1800 && yearInt <= 2027 {
                        foundYears.append(year)
                    }
                }
            }
        }
        
        // Return the first reasonable year found
        return foundYears.first ?? ""
    }
    
    private func extractMediaType(from element: Element) throws -> String {
        // Get the media type from the image in the second cell
        if let img = try element.select("td img").first() {
            let alt = try img.attr("alt")
            return alt
        }
        
        return ""
    }
    
    // Helper method to identify UI elements that should not be considered as content
    private func isUIElement(_ text: String) -> Bool {
        let uiKeywords = [
            "vormerken",
            "bestellen", 
            "vormerken/bestellen",
            "reserve",
            "order",
            "details",
            "ansehen",
            "view",
            "more",
            "weiterlesen",
            "lesen",
            "weiter",
            "zum titel",
            "zur detailansicht"
        ]
        
        let lowercaseText = text.lowercased()
        return uiKeywords.contains { lowercaseText.contains($0) }
    }
    
    private func extractId(from element: Element) throws -> String {
        // First try standard selectors
        let selectors = ["input[name=id]", "[data-id]"]
        for selector in selectors {
            if let idElement = try element.select(selector).first() {
                let idValue = try idElement.val()
                if !idValue.isEmpty {
                    return idValue
                }
            }
        }
        
        // Extract ID from singleHit.do links following SISIS pattern
        // For SISIS, we should store the complete URL path that can be used for detailed retrieval
        if let titleLink = try element.select("a[href*='singleHit.do']").first() {
            let href = try titleLink.attr("href")
            
            // For SISIS, return the relative URL path which contains all necessary parameters
            // This includes methodToCall, curPos, and identifier
            if href.hasPrefix("/webOPACClient/") {
                return href  // Return the complete relative path
            } else if href.contains("singleHit.do") {
                return href  // Return whatever format it's in
            }
        }
        
        return ""
    }
    
    // MARK: - Enhanced Parsing Methods (SISIS-based)
    
    /**
     * Parses detailed media information from SISIS HTML
     * 
     * Extracts comprehensive information including availability,
     * detailed description, and additional bibliographic data.
     * 
     * - Parameters:
     *   - html: Raw HTML content from detailed view
     *   - mediaId: The unique identifier of the media item
     * - Returns: DetailedMedia object or nil if parsing fails
     */
    func parseDetailedMediaInfo(html: String, mediaId: String) -> DetailedMedia? {
        // First extract basic media info
        guard let basicInfo = parseBasicMediaInfo(html: html, mediaId: mediaId) else {
            return nil
        }
        
        // Extract additional details that SISIS provides
        let description = extractDescription(from: html)
        let tableOfContents = extractTableOfContents(from: html)
        let subjects = extractSubjects(from: html)
        let availability = parseAvailability(html: html)
        let additionalInfo = extractAdditionalInfo(from: html)
        let coverImageURLs = extractCoverImageURLs(from: html)
        let edition = extractEdition(from: html)
        let physicalDescription = extractPhysicalDescription(from: html)
        let language = extractLanguage(from: html)
        let notes = extractNotes(from: html)
        
        return DetailedMedia(
            basicInfo: basicInfo,
            description: description,
            tableOfContents: tableOfContents,
            subjects: subjects,
            availability: availability,
            additionalInfo: additionalInfo,
            coverImageURLs: coverImageURLs,
            edition: edition,
            physicalDescription: physicalDescription,
            language: language,
            notes: notes
        )
    }
    
    /**
     * Parses media availability information from SISIS HTML
     * 
     * - Parameter html: Raw HTML content containing availability data
     * - Returns: Array of availability status for each copy
     */
    func parseAvailability(html: String) -> [ItemAvailability] {
        var availabilityList: [ItemAvailability] = []
        
        do {
            let doc = try SwiftSoup.parse(html)
            
            // SISIS typically shows availability in table rows with class containing "availability" or "exemplar"
            let availabilityRows = try doc.select("tr.resultRow, tr[class*=exemplar], tr[class*=availability]")
            
            for row in availabilityRows {
                if let status = parseAvailabilityRow(row) {
                    availabilityList.append(status)
                }
            }
            
            // If no specific availability rows found, try to extract from general result structure
            if availabilityList.isEmpty {
                if let generalStatus = parseGeneralAvailability(from: html) {
                    availabilityList.append(generalStatus)
                }
            }
            
        } catch {
            print("Error parsing availability: \(error)")
        }
        
        return availabilityList
    }
    
    // MARK: - Private Helper Methods for Enhanced Parsing
    
    private func parseBasicMediaInfo(html: String, mediaId: String) -> Media? {
        // Try to extract basic info from detailed view or fall back to simple parsing
        do {
            let doc = try SwiftSoup.parse(html)
            
            // Look for title in various possible locations (SISIS-compatible)
            var title = ""
            
            // Try SISIS-specific selectors first
            let titleSelectors = [
                ".aw_teaser_title",                          // SISIS detailed view title
                ".results-teaser > tbody > tr > td > h1",    // SISIS table title
                "#middle h2",                                // SISIS middle section
                ".data td strong",                           // SISIS data table
                "h1", ".title", ".maintitle",                // Generic selectors
                "strong"                                     // Fallback
            ]
            
            for selector in titleSelectors {
                if let titleElement = try? doc.select(selector).first() {
                    let candidateTitle = try titleElement.text().trimmingCharacters(in: .whitespacesAndNewlines)
                    if !candidateTitle.isEmpty && !isUIElement(candidateTitle) {
                        title = cleanTitle(candidateTitle)
                        break
                    }
                }
            }
            
            // Look for author information using detailed view structure
            var author = ""
            
            // Try SISIS detailed view approach based on Java implementation
            // Look for structured data in table format
            if let detailTable = try? doc.select(".data, #tab-content .data, .box-container .data").first() {
                let detailCells = try detailTable.select("td")
                
                for cell in detailCells {
                    let cellHTML = try cell.html()
                    let cellText = try cell.text()
                    
                    // Look for author indicators in the cell content
                    if cellHTML.contains("Verfasser") || cellHTML.contains("Author") || cellText.contains("Verfasser") {
                        // Extract author from this cell using similar logic to search results
                        let extractedAuthor = extractAuthorFromDetailCell(cell)
                        if !extractedAuthor.isEmpty && isValidAuthorName(extractedAuthor) {
                            author = extractedAuthor
                            break
                        }
                    }
                    
                    // Also try generic author extraction
                    if author.isEmpty {
                        let extractedAuthor = extractAuthorFromDetailCell(cell)
                        if !extractedAuthor.isEmpty && isValidAuthorName(extractedAuthor) && !isAvailabilityText(extractedAuthor) {
                            author = extractedAuthor
                            break
                        }
                    }
                }
            }
            
            // If no author found in structured data, try broader search
            if author.isEmpty {
                let allElements = try doc.select("td, div, span")
                for element in allElements {
                    let elementText = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                    if isValidAuthorName(elementText) && !isAvailabilityText(elementText) {
                        author = cleanAuthor(elementText)
                        break
                    }
                }
            }
            
            // Look for year information (SISIS-compatible)
            var year = ""
            let yearSelectors = [
                ".year", ".erscheinungsjahr", "[class*=year]",  // Generic year selectors
                ".data td"                                       // SISIS data cells
            ]
            
            for selector in yearSelectors {
                let elements = try doc.select(selector)
                for element in elements {
                    let elementText = try element.text()
                    let extractedYear = extractYearFromText(elementText)
                    if !extractedYear.isEmpty {
                        year = extractedYear
                        break
                    }
                }
                if !year.isEmpty { break }
            }
            
            // Look for media type (SISIS-compatible)
            var mediaType = ""
            if let typeElement = try? doc.select(".mediatype, .medientyp, img[alt]").first() {
                if let altText = try? typeElement.attr("alt") {
                    mediaType = altText
                } else {
                    mediaType = try typeElement.text()
                }
                mediaType = mediaType.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Look for basic availability status (SISIS-compatible)
            var availability: AvailabilityType = .availableAtLibrary  // Default to available
            let bodyText = try doc.text().lowercased()
            
            // Use the new availability parsing method
            if let parsedAvailability = AvailabilityType.parse(from: bodyText) {
                availability = parsedAvailability
            } else {
                // Fallback to specific availability elements
                if let availabilityElement = try? doc.select(".availability, .status, [class*='verfügbar'], [class*='ausgeliehen']").first() {
                    let availText = try availabilityElement.text()
                    if let parsedFromElement = AvailabilityType.parse(from: availText) {
                        availability = parsedFromElement
                    }
                }
            }
            
            // Debug output
            print("parseBasicMediaInfo: title='\(title)', author='\(author)', year='\(year)', mediaType='\(mediaType)', availability=\(availability.rawValue)")
            
            return Media(title: title, author: author, year: year, mediaType: mediaType, id: mediaId, availability: availability)
            
        } catch {
            print("Error parsing basic media info: \(error)")
            return nil
        }
    }
    
    /**
     * Extract author information from a detailed view cell
     */
    private func extractAuthorFromDetailCell(_ cell: Element) -> String {
        do {
            let cellHTML = try cell.html()
            
            // Split by various break tags like in search results
            var lines = cellHTML.components(separatedBy: "<br />")
            if lines.count == 1 {
                lines = cellHTML.components(separatedBy: "<br/>")
            }
            if lines.count == 1 {
                lines = cellHTML.components(separatedBy: "<br>")
            }
            
            // Look for author markers
            for line in lines {
                if line.contains("¬[Verfasser]") || line.contains("[Verfasser]") || line.contains("Verfasser:") {
                    // Extract the text part and remove the markers
                    let cleanLine = line.replacingOccurrences(of: "¬[Verfasser]", with: "")
                                       .replacingOccurrences(of: "[Verfasser]", with: "")
                                       .replacingOccurrences(of: "Verfasser:", with: "")
                                       .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    
                    // Remove any remaining HTML tags
                    if let doc = try? SwiftSoup.parse(cleanLine) {
                        let text = try doc.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                                  .replacingOccurrences(of: "¬", with: "")
                        if !text.isEmpty && isValidAuthorName(text) {
                            return text
                        }
                    }
                }
            }
            
            // If no explicit markers, try to find author-like text
            for line in lines {
                // Skip lines with links (likely titles) and empty lines
                if line.contains("href") || line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                    continue
                }
                
                // Parse the line to extract text
                if let doc = try? SwiftSoup.parse(line) {
                    let text = try doc.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                            .replacingOccurrences(of: "¬", with: "")
                    
                    // Check if this looks like a valid author name
                    if isValidAuthorName(text) && !isAvailabilityText(text) {
                        return text
                    }
                }
            }
            
            // Fallback: try the whole cell text
            let cellText = try cell.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if isValidAuthorName(cellText) && !isAvailabilityText(cellText) {
                return cellText
            }
            
        } catch {
            print("Error extracting author from detail cell: \(error)")
        }
        
        return ""
    }
    
    private func parseAvailabilityRow(_ row: Element) -> ItemAvailability? {
        do {
            let rowText = try row.text().lowercased()
            
            // Parse availability status using the new enum
            let status: AvailabilityType
            if let parsedStatus = AvailabilityType.parse(from: rowText) {
                status = parsedStatus
            } else {
                // Fallback to basic logic
                status = (rowText.contains("verfügbar") || 
                         rowText.contains("ausleihbar") ||
                         rowText.contains("vorhanden") ||
                         !rowText.contains("ausgeliehen")) ? 
                         .availableAtLibrary : .checkedOut
            }
            
            // Extract location
            let rowHtml = (try? row.html()) ?? ""
            let location = extractText(from: rowHtml, pattern: #"<td[^>]*class="[^"]*location[^"]*"[^>]*>(.*?)</td>"#) ?? 
                          extractText(from: rowHtml, pattern: #"<td[^>]*>(.*?)</td>"#) ?? ""
            
            // Extract call number
            let callNumber = extractText(from: rowHtml, pattern: #"<td[^>]*class="[^"]*call[^"]*"[^>]*>(.*?)</td>"#) ?? ""
            
            // Extract due date if available
            let dueDate = extractDueDate(from: rowHtml)
            
            // Extract reservation count
            let reservationCount = extractReservationCount(from: rowHtml)
            
            return ItemAvailability(
                status: status,
                location: location.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                callNumber: callNumber.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                dueDate: dueDate,
                reservationCount: reservationCount
            )
            
        } catch {
            print("Error parsing availability row: \(error)")
            return nil
        }
    }
    
    private func parseGeneralAvailability(from html: String) -> ItemAvailability? {
        // Create a general availability status when specific data isn't available
        let status: AvailabilityType
        if let parsedStatus = AvailabilityType.parse(from: html.lowercased()) {
            status = parsedStatus
        } else {
            status = (html.lowercased().contains("verfügbar") || 
                     html.lowercased().contains("ausleihbar")) ?
                     .availableAtLibrary : .checkedOut
        }
        
        return ItemAvailability(
            status: status,
            location: "Bibliothek",
            callNumber: "",
            dueDate: nil,
            reservationCount: 0
        )
    }
    
    private func extractDescription(from html: String) -> String? {
        return extractText(from: html, pattern: #"<div[^>]*class="[^"]*description[^"]*"[^>]*>(.*?)</div>"#)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    private func extractTableOfContents(from html: String) -> [String] {
        guard let tocText = extractText(from: html, pattern: #"<div[^>]*class="[^"]*toc[^"]*"[^>]*>(.*?)</div>"#) else {
            return []
        }
        
        return tocText.components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func extractSubjects(from html: String) -> [String] {
        guard let subjectsText = extractText(from: html, pattern: #"<div[^>]*class="[^"]*subject[^"]*"[^>]*>(.*?)</div>"#) else {
            return []
        }
        
        return subjectsText.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func extractAdditionalInfo(from html: String) -> [String: String] {
        var info: [String: String] = [:]
        
        // Extract ISBN
        if let isbn = extractText(from: html, pattern: #"ISBN[:\s]*([0-9\-X]+)"#) {
            info["ISBN"] = isbn
        }
        
        // Extract publisher
        if let publisher = extractText(from: html, pattern: #"Verlag[:\s]*([^<\n]+)"#) {
            info["Verlag"] = publisher.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        
        return info
    }
    
    private func extractCoverImageURLs(from html: String) -> [String] {
        let pattern = #"<img[^>]*src="([^"]*cover[^"]*)"[^>]*>"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let nsString = html as NSString
        let results = regex?.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        return results.compactMap { result in
            if result.numberOfRanges > 1 {
                let urlRange = result.range(at: 1)
                return nsString.substring(with: urlRange)
            }
            return nil
        }
    }
    
    private func extractEdition(from html: String) -> String? {
        return extractText(from: html, pattern: #"Auflage[:\s]*([^<\n]+)"#)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    private func extractPhysicalDescription(from html: String) -> String? {
        return extractText(from: html, pattern: #"Umfang[:\s]*([^<\n]+)"#)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    private func extractLanguage(from html: String) -> String? {
        return extractText(from: html, pattern: #"Sprache[:\s]*([^<\n]+)"#)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    private func extractNotes(from html: String) -> [String] {
        guard let notesText = extractText(from: html, pattern: #"<div[^>]*class="[^"]*notes[^"]*"[^>]*>(.*?)</div>"#) else {
            return []
        }
        
        return notesText.components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func extractDueDate(from html: String) -> Date? {
        let datePattern = #"(\d{1,2})\.(\d{1,2})\.(\d{4})"#
        guard let regex = try? NSRegularExpression(pattern: datePattern),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              match.numberOfRanges == 4 else {
            return nil
        }
        
        let day = Int(String(html[Range(match.range(at: 1), in: html)!])) ?? 0
        let month = Int(String(html[Range(match.range(at: 2), in: html)!])) ?? 0
        let year = Int(String(html[Range(match.range(at: 3), in: html)!])) ?? 0
        
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        
        return Calendar.current.date(from: components)
    }
    
    private func extractReservationCount(from html: String) -> Int {
        let reservationPattern = #"(\d+)\s*Vormerkung"#
        guard let reservationText = extractText(from: html, pattern: reservationPattern) else {
            return 0
        }
        
        return Int(reservationText) ?? 0
    }
    
    // MARK: - Utility Methods for Enhanced Parsing
    
    /**
     * Extracts text using regex pattern from HTML string
     * 
     * - Parameters:
     *   - html: The HTML string to search in
     *   - pattern: Regular expression pattern to match
     * - Returns: First captured group or nil if no match
     */
    private func extractText(from html: String, pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let nsString = html as NSString
            
            if let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length)),
               match.numberOfRanges > 1 {
                let captureRange = match.range(at: 1)
                let capturedText = nsString.substring(with: captureRange)
                
                // Clean HTML tags from the captured text
                return try SwiftSoup.parse(capturedText).text()
            }
        } catch {
            print("Error in regex extraction: \(error)")
        }
        
        return nil
    }
    
    /**
     * Cleans title text by removing unwanted characters and formatting
     * 
     * - Parameter title: Raw title text
     * - Returns: Cleaned title
     */
    private func cleanTitle(_ title: String) -> String {
        var cleaned = title
        
        // Remove leading/trailing special characters
        if cleaned.hasPrefix("¬") {
            cleaned = String(cleaned.dropFirst())
        }
        
        // Remove unwanted suffixes
        cleaned = cleaned.replacingOccurrences(of: " [Elektronische Ressource]", with: "")
        cleaned = cleaned.replacingOccurrences(of: " [Online-Ressource]", with: "")
        
        return cleaned.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    /**
     * Cleans author text by removing metadata and formatting
     * 
     * - Parameter author: Raw author text
     * - Returns: Cleaned author name
     */
    private func cleanAuthor(_ author: String) -> String {
        var cleaned = author
        
        // Remove common German OPAC author indicators
        cleaned = cleaned.replacingOccurrences(of: "¬[Verfasser]", with: "")
        cleaned = cleaned.replacingOccurrences(of: "[Verfasser]", with: "")
        cleaned = cleaned.replacingOccurrences(of: "¬[Herausgeber]", with: "")
        cleaned = cleaned.replacingOccurrences(of: "[Herausgeber]", with: "")
        cleaned = cleaned.replacingOccurrences(of: "¬[Autor]", with: "")
        cleaned = cleaned.replacingOccurrences(of: "[Autor]", with: "")
        
        // Remove leading ¬ character
        if cleaned.hasPrefix("¬") {
            cleaned = String(cleaned.dropFirst())
        }
        
        return cleaned.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    /**
     * Extracts year from text using various patterns
     * 
     * - Parameter text: Text containing year information
     * - Returns: Extracted year as string
     */
    private func extractYearFromText(_ text: String) -> String {
        // Try various year patterns
        let patterns = [
            #"\b(20\d{2}|\b19\d{2})\b"#,  // 4-digit years from 1900-2099
            #"\[(\d{4})\]"#,               // Years in brackets
            #"(\d{4})"#                    // Any 4-digit number
        ]
        
        for pattern in patterns {
            if let year = extractText(from: text, pattern: pattern) {
                if let yearInt = Int(year), yearInt >= 1800 && yearInt <= 2030 {
                    return year
                }
            }
        }
        
        return ""
    }
    
    // MARK: - SISIS-compatible URL Building
    
    /**
     * Builds detailed media URL following SISIS pattern from Java implementation
     * 
     * Java SISIS uses: /start.do?searchType=1&Query=0%3D%22{id}%22
     * This method replicates that pattern for Swift implementation.
     * 
     * - Parameters:
     *   - baseURL: Base OPAC URL
     *   - mediaId: The media identifier extracted from search results
     *   - startParams: Optional start parameters (e.g., "Login=foo")
     *   - selectedBranch: Optional selected branch parameter
     * - Returns: Complete URL for fetching detailed media information
     */
    func buildDetailedMediaURL(baseURL: String, mediaId: String, startParams: String? = nil, selectedBranch: String? = nil) -> String {
        var url = "\(baseURL)/start.do?"
        
        // Add start parameters if provided (Java SISIS compatibility)
        if let startParams = startParams, !startParams.isEmpty {
            url += "\(startParams)&"
        }
        
        // Add the SISIS-style query pattern: searchType=1&Query=0%3D%22{id}%22
        url += "searchType=1&Query=0%3D%22\(mediaId)%22"
        
        // Add selected branch if provided
        if let selectedBranch = selectedBranch, !selectedBranch.isEmpty {
            url += "&selectedViewBranchlib=\(selectedBranch)"
        }
        
        return url
    }
    
    /**
     * Builds position-based media URL for paginated results (Java SISIS pattern)
     * 
     * Java SISIS uses: /singleHit.do?tab=showExemplarActive&methodToCall=showHit&curPos={position}&identifier={identifier}
     * 
     * - Parameters:
     *   - baseURL: Base OPAC URL
     *   - position: Position in search results (1-based)
     *   - identifier: The search session identifier
     * - Returns: Complete URL for fetching media at specific position
     */
    func buildPositionBasedMediaURL(baseURL: String, position: Int, identifier: String) -> String {
        return "\(baseURL)/singleHit.do?tab=showExemplarActive&methodToCall=showHit&curPos=\(position)&identifier=\(identifier)"
    }
    
    /**
     * Extracts basic availability status from search result row
     * 
     * SISIS search results typically show basic availability indicators
     * like "verfügbar", "ausgeliehen", "nicht verfügbar" in the result rows.
     * 
     * - Parameter element: The search result row element
     * - Returns: Basic availability status (true = available, false = not available)
     * - Throws: SwiftSoup parsing errors
     */
    private func extractBasicAvailability(from element: Element) throws -> AvailabilityType {
        let rowText = try element.text().lowercased()
        
        // Use the new AvailabilityType parsing method
        if let parsedStatus = AvailabilityType.parse(from: rowText) {
            return parsedStatus
        }
        
        // Check for explicit availability indicators using pattern matching
        if rowText.contains("verfügbar") || rowText.contains("ausleihbar") {
            if rowText.contains("gewählten bibliothek") {
                return .availableAtLibrary
            }
            return .availableAtLibrary
        }
        
        if rowText.contains("ausgeliehen") || rowText.contains("entliehen") {
            return .checkedOut
        }
        
        if rowText.contains("nicht verfügbar") {
            return .notAvailable
        }
        
        if rowText.contains("vorgemerkt") {
            return .reserved
        }
        
        if rowText.contains("bestellt") {
            return .onOrder
        }
        
        if rowText.contains("nicht ausleihbar") {
            return .notLendable
        }
        
        if rowText.contains("heute zurück") {
            return .dueTodayReturns
        }
        
        if rowText.contains("vormerkbar") {
            return .reservable
        }
        
        if rowText.contains("bestellbar") {
            if rowText.contains("anderer bibliothek") {
                return .orderable
            }
            return .orderable
        }
        
        // Check for status indicators in specific cells or elements
        let statusElements = try element.select("td[class*='status'], td[class*='availability'], .status-cell, .availability-status, td img[alt*='status'], td img[alt*='verfügbar'], td img[alt*='ausgeliehen']")
        for statusElement in statusElements {
            let elementText = try statusElement.text().lowercased()
            let altText = try statusElement.attr("alt").lowercased()
            
            let combinedText = elementText + " " + altText
            if let parsedStatus = AvailabilityType.parse(from: combinedText) {
                return parsedStatus
            }
        }
        
        // Look for status information in the main data cell
        let cells = try element.select("td")
        if cells.size() > 1 {
            let mainCell = try element.select("td[style*='width:100%']").first() ?? cells.get(1)
            let cellText = try mainCell.text().lowercased()
            
            if let parsedStatus = AvailabilityType.parse(from: cellText) {
                return parsedStatus
            }
        }
        
        // Default to available if no clear status indicators found
        // This follows the principle that items are generally available unless explicitly marked otherwise
        return .availableAtLibrary
    }
}
