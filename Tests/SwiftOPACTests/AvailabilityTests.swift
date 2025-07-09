import XCTest
@testable import SwiftOPAC

/**
 * Tests for the availability status system
 * 
 * Validates the parsing and handling of different German OPAC availability states
 * and ensures proper mapping to the AvailabilityType enum.
 */
final class AvailabilityTests: XCTestCase {
    
    // MARK: - AvailabilityType Parsing Tests
    
    func testParseAvailableAtLibrary() throws {
        // Test basic availability
        XCTAssertEqual(AvailabilityType.parse(from: "ausleihbar"), .availableAtLibrary)
        XCTAssertEqual(AvailabilityType.parse(from: "verfügbar"), .availableAtLibrary)
        
        // Test specific library availability
        XCTAssertEqual(AvailabilityType.parse(from: "ausleihbar (in der gewählten Bibliothek)"), .availableAtLibrary)
    }
    
    func testParseCheckedOut() throws {
        XCTAssertEqual(AvailabilityType.parse(from: "entliehen"), .checkedOut)
        XCTAssertEqual(AvailabilityType.parse(from: "ausgeliehen"), .checkedOut)
    }
    
    func testParseOrderable() throws {
        XCTAssertEqual(AvailabilityType.parse(from: "bestellbar"), .orderable)
        XCTAssertEqual(AvailabilityType.parse(from: "bestellbar (aus anderer Bibliothek)"), .orderable)
    }
    
    func testParseReservable() throws {
        XCTAssertEqual(AvailabilityType.parse(from: "vormerkbar"), .reservable)
    }
    
    func testParseReserved() throws {
        XCTAssertEqual(AvailabilityType.parse(from: "vorgemerkt"), .reserved)
    }
    
    func testParseOnOrder() throws {
        XCTAssertEqual(AvailabilityType.parse(from: "bestellt"), .onOrder)
    }
    
    func testParseNotAvailable() throws {
        XCTAssertEqual(AvailabilityType.parse(from: "nicht verfügbar"), .notAvailable)
        XCTAssertEqual(AvailabilityType.parse(from: "nicht ausleihbar"), .notLendable)
    }
    
    func testParsePresentOnly() throws {
        XCTAssertEqual(AvailabilityType.parse(from: "präsenzbestand"), .availableReferenceOnly)
        XCTAssertEqual(AvailabilityType.parse(from: "präsenz"), .availableReferenceOnly)
    }
    
    func testParseDueTodayReturns() throws {
        XCTAssertEqual(AvailabilityType.parse(from: "heute zurück"), .dueTodayReturns)
        XCTAssertEqual(AvailabilityType.parse(from: "heute_zurück"), .dueTodayReturns)
    }
    
    func testParseMagazine() throws {
        XCTAssertEqual(AvailabilityType.parse(from: "magazin"), .magazin)
    }
    
    func testParseUnknownStatus() throws {
        // Unknown statuses should return nil
        XCTAssertNil(AvailabilityType.parse(from: "unknown status"))
        XCTAssertNil(AvailabilityType.parse(from: ""))
        XCTAssertNil(AvailabilityType.parse(from: "some random text"))
    }
    
    // MARK: - AvailabilityType Properties Tests
    
    func testIsAccessible() throws {
        // Should be accessible
        XCTAssertTrue(AvailabilityType.availableAtLibrary.isAccessible)
        XCTAssertTrue(AvailabilityType.availableReferenceOnly.isAccessible)
        XCTAssertTrue(AvailabilityType.dueTodayReturns.isAccessible)
        XCTAssertTrue(AvailabilityType.reservable.isAccessible)
        XCTAssertTrue(AvailabilityType.orderable.isAccessible)
        XCTAssertTrue(AvailabilityType.magazin.isAccessible)
        
        // Should not be accessible
        XCTAssertFalse(AvailabilityType.checkedOut.isAccessible)
        XCTAssertFalse(AvailabilityType.missing.isAccessible)
        XCTAssertFalse(AvailabilityType.notAvailable.isAccessible)
        XCTAssertFalse(AvailabilityType.notLendable.isAccessible)
    }
    
    func testIsImmediatelyAvailable() throws {
        // Should be immediately available
        XCTAssertTrue(AvailabilityType.availableAtLibrary.isImmediatelyAvailable)
        XCTAssertTrue(AvailabilityType.availableProcessing.isImmediatelyAvailable)
        XCTAssertTrue(AvailabilityType.dueTodayReturns.isImmediatelyAvailable)
        
        // Should not be immediately available
        XCTAssertFalse(AvailabilityType.checkedOut.isImmediatelyAvailable)
        XCTAssertFalse(AvailabilityType.reserved.isImmediatelyAvailable)
        XCTAssertFalse(AvailabilityType.orderable.isImmediatelyAvailable)
        XCTAssertFalse(AvailabilityType.availableReferenceOnly.isImmediatelyAvailable)
    }
    
    func testCanBeRequested() throws {
        // Can be requested
        XCTAssertTrue(AvailabilityType.reservable.canBeRequested)
        XCTAssertTrue(AvailabilityType.orderable.canBeRequested)
        XCTAssertTrue(AvailabilityType.checkedOut.canBeRequested)
        XCTAssertTrue(AvailabilityType.reserved.canBeRequested)
        
        // Cannot be requested
        XCTAssertFalse(AvailabilityType.availableAtLibrary.canBeRequested)
        XCTAssertFalse(AvailabilityType.notAvailable.canBeRequested)
        XCTAssertFalse(AvailabilityType.missing.canBeRequested)
    }
    
    func testLocalizedDescriptions() throws {
        XCTAssertEqual(AvailabilityType.availableAtLibrary.localizedDescription, "Ausleihbar (in der gewählten Bibliothek)")
        XCTAssertEqual(AvailabilityType.orderable.localizedDescription, "Bestellbar (aus anderer Bibliothek)")
        XCTAssertEqual(AvailabilityType.availableReferenceOnly.localizedDescription, "Präsenzbestand (nur zur Einsichtnahme)")
        XCTAssertEqual(AvailabilityType.checkedOut.localizedDescription, "Ausgeliehen")
        XCTAssertEqual(AvailabilityType.dueTodayReturns.localizedDescription, "Heute zurück erwartet")
    }
    
    func testStatusColors() throws {
        // Green for immediately available
        XCTAssertEqual(AvailabilityType.availableAtLibrary.statusColor, "green")
        XCTAssertEqual(AvailabilityType.dueTodayReturns.statusColor, "green")
        
        // Yellow for conditional availability
        XCTAssertEqual(AvailabilityType.availableReferenceOnly.statusColor, "yellow")
        XCTAssertEqual(AvailabilityType.reservable.statusColor, "yellow")
        XCTAssertEqual(AvailabilityType.orderable.statusColor, "yellow")
        
        // Orange for temporary unavailability
        XCTAssertEqual(AvailabilityType.checkedOut.statusColor, "orange")
        XCTAssertEqual(AvailabilityType.reserved.statusColor, "orange")
        
        // Red for permanently unavailable
        XCTAssertEqual(AvailabilityType.notAvailable.statusColor, "red")
        XCTAssertEqual(AvailabilityType.missing.statusColor, "red")
    }
    
    // MARK: - ItemAvailability Tests
    
    func testItemAvailabilityInit() throws {
        let availability = ItemAvailability(
            status: .availableAtLibrary,
            location: "Zentralbibliothek, 2. OG",
            callNumber: "PS 3545 .O337 Z5 2018"
        )
        
        XCTAssertEqual(availability.status, .availableAtLibrary)
        XCTAssertEqual(availability.location, "Zentralbibliothek, 2. OG")
        XCTAssertEqual(availability.callNumber, "PS 3545 .O337 Z5 2018")
        XCTAssertTrue(availability.isAvailable) // Legacy compatibility
    }
    
    func testItemAvailabilityWithDueDate() throws {
        let dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let availability = ItemAvailability(
            status: .checkedOut,
            location: "Teilbibliothek Informatik",
            callNumber: "QA 76.73 .S94 K67 2019",
            dueDate: dueDate,
            reservationCount: 2
        )
        
        XCTAssertEqual(availability.status, .checkedOut)
        XCTAssertEqual(availability.reservationCount, 2)
        XCTAssertNotNil(availability.dueDate)
        XCTAssertFalse(availability.isAvailable) // Legacy compatibility
    }
    
    func testAvailabilityDescription() throws {
        let availability = ItemAvailability(
            status: .availableAtLibrary,
            location: "Hauptbibliothek",
            callNumber: "B 3376 .W563 D513 2020"
        )
        
        XCTAssertTrue(availability.availabilityDescription.contains("Ausleihbar"))
        XCTAssertTrue(availability.fullDescription.contains("Hauptbibliothek"))
        XCTAssertTrue(availability.fullDescription.contains("B 3376 .W563 D513 2020"))
    }
    
    // MARK: - Media Integration Tests
    
    func testMediaWithAvailability() throws {
        let media = Media(
            title: "Test Book",
            author: "Test Author",
            year: "2024",
            mediaType: "Buch",
            id: "12345",
            availability: .orderable
        )
        
        XCTAssertEqual(media.availability, .orderable)
        XCTAssertFalse(media.isAvailable) // Legacy compatibility - orderable is not immediately available
    }
    
    func testMediaLegacyInitializer() throws {
        // Test backward compatibility with boolean initializer
        let mediaAvailable = Media(
            title: "Available Book",
            author: "Test Author",
            year: "2024",
            mediaType: "Buch",
            id: "12345",
            isAvailable: true
        )
        
        XCTAssertEqual(mediaAvailable.availability, .availableAtLibrary)
        XCTAssertTrue(mediaAvailable.isAvailable)
        
        let mediaUnavailable = Media(
            title: "Unavailable Book",
            author: "Test Author",
            year: "2024",
            mediaType: "Buch",
            id: "12346",
            isAvailable: false
        )
        
        XCTAssertEqual(mediaUnavailable.availability, .checkedOut)
        XCTAssertFalse(mediaUnavailable.isAvailable)
    }
    
    // MARK: - DetailedMedia Integration Tests
    
    func testDetailedMediaAvailability() throws {
        let basicInfo = Media(
            title: "Advanced Swift Programming",
            author: "John Developer",
            year: "2024",
            mediaType: "Buch",
            id: "67890",
            availability: .availableAtLibrary
        )
        
        let availabilities = [
            ItemAvailability(
                status: .availableAtLibrary,
                location: "Zentralbibliothek",
                callNumber: "QA 76.73 .S94 2024"
            ),
            ItemAvailability(
                status: .checkedOut,
                location: "Teilbibliothek Informatik",
                callNumber: "QA 76.73 .S94 2024",
                dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                reservationCount: 1
            )
        ]
        
        let detailedMedia = DetailedMedia(
            basicInfo: basicInfo,
            availability: availabilities
        )
        
        XCTAssertEqual(detailedMedia.totalCopies, 2)
        XCTAssertEqual(detailedMedia.availableCopies, 1)
        XCTAssertTrue(detailedMedia.hasAvailableCopies)
        XCTAssertEqual(detailedMedia.totalReservations, 1)
        XCTAssertTrue(detailedMedia.availabilitySummary.contains("1 von 2 verfügbar"))
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testEmptyAndWhitespaceInput() throws {
        XCTAssertNil(AvailabilityType.parse(from: ""))
        XCTAssertNil(AvailabilityType.parse(from: "   "))
        XCTAssertNil(AvailabilityType.parse(from: "\n\t"))
    }
    
    func testCaseInsensitiveParsing() throws {
        XCTAssertEqual(AvailabilityType.parse(from: "AUSLEIHBAR"), .availableAtLibrary)
        XCTAssertEqual(AvailabilityType.parse(from: "Verfügbar"), .availableAtLibrary)
        XCTAssertEqual(AvailabilityType.parse(from: "Entliehen"), .checkedOut)
    }
    
    func testPartialMatches() throws {
        // Should match even with additional text
        XCTAssertEqual(AvailabilityType.parse(from: "Status: ausleihbar in Bibliothek"), .availableAtLibrary)
        XCTAssertEqual(AvailabilityType.parse(from: "Exemplar ist entliehen bis 15.03.2024"), .checkedOut)
        XCTAssertEqual(AvailabilityType.parse(from: "Bestellbar aus anderer Bibliothek (Fernleihe)"), .orderable)
    }
}
