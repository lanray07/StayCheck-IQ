import Foundation
import SwiftData

enum UserType: String, CaseIterable, Identifiable, Codable {
    case airbnbHost = "Airbnb host"
    case coHost = "Co-host"
    case cleaner = "Cleaner"
    case propertyManager = "Property manager"
    case servicedAccommodationOperator = "Serviced accommodation operator"

    var id: String { rawValue }
}

enum PropertyType: String, CaseIterable, Identifiable, Codable {
    case apartment = "Apartment"
    case house = "House"
    case studio = "Studio"
    case townhouse = "Townhouse"
    case servicedApartment = "Serviced apartment"
    case other = "Other"

    var id: String { rawValue }
}

enum ChecklistSection: String, CaseIterable, Identifiable, Codable {
    case kitchen = "Kitchen"
    case bathroom = "Bathroom"
    case bedroom = "Bedroom"
    case livingRoom = "Living room"
    case hallway = "Hallway"
    case exterior = "Exterior"
    case linen = "Linen"
    case inventory = "Inventory"
    case safetyItems = "Safety items"
    case customArea = "Custom area"

    var id: String { rawValue }
}

enum BeforeAfterType: String, CaseIterable, Identifiable, Codable {
    case before = "Before"
    case after = "After"
    case reference = "Reference"

    var id: String { rawValue }
}

enum IssueCategory: String, CaseIterable, Identifiable, Codable {
    case cleaningIssue = "Cleaning issue"
    case damage = "Damage"
    case missingItem = "Missing item"
    case lowStock = "Low stock"
    case linenIssue = "Linen issue"
    case bathroomIssue = "Bathroom issue"
    case kitchenIssue = "Kitchen issue"
    case safetyConcern = "Safety concern"
    case maintenanceConcern = "Maintenance concern"

    var id: String { rawValue }
}

enum IssueSeverity: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var id: String { rawValue }

    var rank: Int {
        switch self {
        case .low:
            return 1
        case .medium:
            return 2
        case .high:
            return 3
        case .urgent:
            return 4
        }
    }
}

enum IssueStatus: String, CaseIterable, Identifiable, Codable {
    case open = "Open"
    case assigned = "Assigned"
    case resolved = "Resolved"
    case deferred = "Deferred"

    var id: String { rawValue }
}

enum TurnoverStatus: String, CaseIterable, Identifiable, Codable {
    case draft = "Draft"
    case inProgress = "In progress"
    case needsReview = "Needs review"
    case completed = "Completed"
    case notReady = "Not ready"

    var id: String { rawValue }
}

enum InventoryCategory: String, CaseIterable, Identifiable, Codable {
    case towels = "Towels"
    case bedding = "Bedding"
    case toiletPaper = "Toilet paper"
    case soap = "Soap"
    case shampoo = "Shampoo"
    case teaCoffee = "Tea/coffee"
    case cleaningProducts = "Cleaning products"
    case batteries = "Batteries"
    case keys = "Keys"
    case remotes = "Remotes"
    case kitchenItems = "Kitchen items"

    var id: String { rawValue }
}

enum GuestReadyStatus: String, CaseIterable, Identifiable, Codable {
    case ready = "Ready"
    case needsReview = "Needs Review"
    case notReady = "Not Ready"

    var id: String { rawValue }
}

@Model
final class RentalProperty {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var propertyType: String
    var bedrooms: Int
    var bathrooms: Int
    var assignedCleaner: String
    var checkInTime: Date
    var checkOutTime: Date
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        address: String = "",
        propertyType: String = PropertyType.apartment.rawValue,
        bedrooms: Int = 1,
        bathrooms: Int = 1,
        assignedCleaner: String = "",
        checkInTime: Date = Date(),
        checkOutTime: Date = Date(),
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.propertyType = propertyType
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.assignedCleaner = assignedCleaner
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.notes = notes
        self.createdAt = createdAt
    }
}

@Model
final class TurnoverCheck {
    @Attribute(.unique) var id: UUID
    var propertyId: UUID
    var date: Date
    var cleanerName: String
    var status: String
    var guestReadyScore: Int
    var guestReadyStatus: String
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        propertyId: UUID,
        date: Date = Date(),
        cleanerName: String = "",
        status: String = TurnoverStatus.inProgress.rawValue,
        guestReadyScore: Int = 0,
        guestReadyStatus: String = GuestReadyStatus.needsReview.rawValue,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.propertyId = propertyId
        self.date = date
        self.cleanerName = cleanerName
        self.status = status
        self.guestReadyScore = guestReadyScore
        self.guestReadyStatus = guestReadyStatus
        self.notes = notes
        self.createdAt = createdAt
    }
}

@Model
final class TurnoverChecklistItem {
    @Attribute(.unique) var id: UUID
    var turnoverCheckId: UUID
    var section: String
    var title: String
    var completed: Bool
    var cleaned: Bool
    var restocked: Bool
    var photoRequired: Bool
    var photoProofAdded: Bool
    var issueFound: Bool
    var guestReady: Bool
    var notes: String
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        turnoverCheckId: UUID,
        section: String,
        title: String,
        completed: Bool = false,
        cleaned: Bool = false,
        restocked: Bool = false,
        photoRequired: Bool = false,
        photoProofAdded: Bool = false,
        issueFound: Bool = false,
        guestReady: Bool = false,
        notes: String = "",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.turnoverCheckId = turnoverCheckId
        self.section = section
        self.title = title
        self.completed = completed
        self.cleaned = cleaned
        self.restocked = restocked
        self.photoRequired = photoRequired
        self.photoProofAdded = photoProofAdded
        self.issueFound = issueFound
        self.guestReady = guestReady
        self.notes = notes
        self.sortOrder = sortOrder
    }
}

@Model
final class RoomPhoto {
    @Attribute(.unique) var id: UUID
    var turnoverCheckId: UUID
    var room: String
    @Attribute(.externalStorage) var imageData: Data?
    var localImagePath: String
    var caption: String
    var beforeAfterType: String
    var notes: String
    var flagIssue: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        turnoverCheckId: UUID,
        room: String = ChecklistSection.kitchen.rawValue,
        imageData: Data? = nil,
        localImagePath: String = "",
        caption: String = "",
        beforeAfterType: String = BeforeAfterType.after.rawValue,
        notes: String = "",
        flagIssue: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.turnoverCheckId = turnoverCheckId
        self.room = room
        self.imageData = imageData
        self.localImagePath = localImagePath
        self.caption = caption
        self.beforeAfterType = beforeAfterType
        self.notes = notes
        self.flagIssue = flagIssue
        self.createdAt = createdAt
    }
}

@Model
final class StayIssue {
    @Attribute(.unique) var id: UUID
    var propertyId: UUID
    var turnoverCheckId: UUID?
    var photoId: UUID?
    var title: String
    var room: String
    var issueDescription: String
    var category: String
    var severity: String
    var suggestedAction: String
    var assignedAction: String
    var status: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        propertyId: UUID,
        turnoverCheckId: UUID? = nil,
        photoId: UUID? = nil,
        title: String = "",
        room: String = ChecklistSection.kitchen.rawValue,
        issueDescription: String = "",
        category: String = IssueCategory.cleaningIssue.rawValue,
        severity: String = IssueSeverity.low.rawValue,
        suggestedAction: String = "",
        assignedAction: String = "",
        status: String = IssueStatus.open.rawValue,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.propertyId = propertyId
        self.turnoverCheckId = turnoverCheckId
        self.photoId = photoId
        self.title = title
        self.room = room
        self.issueDescription = issueDescription
        self.category = category
        self.severity = severity
        self.suggestedAction = suggestedAction
        self.assignedAction = assignedAction
        self.status = status
        self.createdAt = createdAt
    }
}

@Model
final class InventoryItem {
    @Attribute(.unique) var id: UUID
    var propertyId: UUID
    var name: String
    var category: String
    var currentQuantity: Int
    var minimumQuantity: Int
    var needsRestock: Bool
    var notes: String

    init(
        id: UUID = UUID(),
        propertyId: UUID,
        name: String = "",
        category: String = InventoryCategory.towels.rawValue,
        currentQuantity: Int = 0,
        minimumQuantity: Int = 1,
        needsRestock: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.propertyId = propertyId
        self.name = name
        self.category = category
        self.currentQuantity = currentQuantity
        self.minimumQuantity = minimumQuantity
        self.needsRestock = needsRestock
        self.notes = notes
    }
}

@Model
final class TurnoverReport {
    @Attribute(.unique) var id: UUID
    var turnoverCheckId: UUID
    var propertyId: UUID
    var title: String
    var summary: String
    var pdfLocalPath: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        turnoverCheckId: UUID,
        propertyId: UUID,
        title: String,
        summary: String = "",
        pdfLocalPath: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.turnoverCheckId = turnoverCheckId
        self.propertyId = propertyId
        self.title = title
        self.summary = summary
        self.pdfLocalPath = pdfLocalPath
        self.createdAt = createdAt
    }

    var pdfURL: URL? {
        guard !pdfLocalPath.isEmpty else { return nil }
        return URL(fileURLWithPath: pdfLocalPath)
    }
}
