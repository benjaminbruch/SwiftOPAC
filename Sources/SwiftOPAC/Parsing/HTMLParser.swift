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
                
                // Only add if we have a valid title and it's not a UI element
                if !title.isEmpty && !isUIElement(title) && title != author {
                    media.append(Media(title: title, author: author, year: year, mediaType: mediaType, id: id))
                    if media.count <= 3 {
                        print("Added media: title='\(title)', author='\(author)', year='\(year)', type='\(mediaType)'")
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
        // Get the main data cell
        let cells = try element.select("td")
        guard cells.size() > 1 else { return "" }
        
        let mainCell = try element.select("td[style*='width:100%']").first() ?? 
                      cells.get(1)
        
        // Get the HTML content and parse it manually since the author is not in a specific tag
        let cellHTML = try mainCell.html()
        
        // Look for pattern: author name followed by ¬[Verfasser]
        let lines = cellHTML.components(separatedBy: "<br />")
        for line in lines {
            if line.contains("¬[Verfasser]") {
                // Extract the text part and remove the ¬[Verfasser] part
                let cleanLine = line.replacingOccurrences(of: "¬[Verfasser]", with: "")
                                   .trimmingCharacters(in: .whitespacesAndNewlines)
                // Remove any remaining HTML tags
                if let doc = try? SwiftSoup.parse(cleanLine),
                   let text = try? doc.text() {
                    let author = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !author.isEmpty && !isUIElement(author) {
                        return author
                    }
                }
            }
        }
        
        return ""
    }
    
    private func extractYear(from element: Element) throws -> String {
        // Get the main data cell
        let cells = try element.select("td")
        guard cells.size() > 1 else { return "" }
        
        let mainCell = try element.select("td[style*='width:100%']").first() ?? 
                      cells.get(1)
        
        let cellHTML = try mainCell.html()
        let lines = cellHTML.components(separatedBy: "<br />")
        
        // Year is typically on the third line (after title and author)
        for line in lines {
            // Look for year patterns: 2024, [2024], etc.
            let yearPattern = #"\[?(\d{4})\]?"#
            if let regex = try? NSRegularExpression(pattern: yearPattern),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                let yearRange = Range(match.range(at: 1), in: line)!
                return String(line[yearRange])
            }
        }
        
        return ""
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
        let selectors = ["input[name=id]", "[data-id]"]
        for selector in selectors {
            if let idElement = try element.select(selector).first() {
                return try idElement.val()
            }
        }
        return ""
    }
}
