import Foundation
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var selectedUserType: UserType = .airbnbHost
    @Published var propertyCount = 1
    @Published var acceptedDisclaimer = false

    var canContinue: Bool {
        acceptedDisclaimer && propertyCount > 0
    }
}

@MainActor
final class PropertyFormViewModel: ObservableObject {
    @Published var name: String
    @Published var address: String
    @Published var propertyType: PropertyType
    @Published var bedrooms: Int
    @Published var bathrooms: Int
    @Published var assignedCleaner: String
    @Published var checkInTime: Date
    @Published var checkOutTime: Date
    @Published var notes: String

    init(property: RentalProperty? = nil) {
        self.name = property?.name ?? ""
        self.address = property?.address ?? ""
        self.propertyType = PropertyType(rawValue: property?.propertyType ?? "") ?? .apartment
        self.bedrooms = property?.bedrooms ?? 1
        self.bathrooms = property?.bathrooms ?? 1
        self.assignedCleaner = property?.assignedCleaner ?? ""
        self.checkInTime = property?.checkInTime ?? .todayAt(hour: 15)
        self.checkOutTime = property?.checkOutTime ?? .todayAt(hour: 10)
        self.notes = property?.notes ?? ""
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func makeProperty() -> RentalProperty {
        RentalProperty(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            propertyType: propertyType.rawValue,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            assignedCleaner: assignedCleaner.trimmingCharacters(in: .whitespacesAndNewlines),
            checkInTime: checkInTime,
            checkOutTime: checkOutTime,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func apply(to property: RentalProperty) {
        property.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        property.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        property.propertyType = propertyType.rawValue
        property.bedrooms = bedrooms
        property.bathrooms = bathrooms
        property.assignedCleaner = assignedCleaner.trimmingCharacters(in: .whitespacesAndNewlines)
        property.checkInTime = checkInTime
        property.checkOutTime = checkOutTime
        property.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
final class NewTurnoverViewModel: ObservableObject {
    @Published var date = Date()
    @Published var cleanerName = ""
    @Published var notes = ""

    func makeCheck(for property: RentalProperty) -> TurnoverCheck {
        TurnoverCheck(
            propertyId: property.id,
            date: date,
            cleanerName: cleanerName.isEmpty ? property.assignedCleaner : cleanerName,
            notes: notes
        )
    }
}

@MainActor
final class PhotoUploadViewModel: ObservableObject {
    @Published var room: ChecklistSection = .kitchen
    @Published var caption = ""
    @Published var beforeAfterType: BeforeAfterType = .after
    @Published var notes = ""
    @Published var flagIssue = false

    func makePhoto(turnoverCheckId: UUID, imageData: Data) -> RoomPhoto {
        RoomPhoto(
            turnoverCheckId: turnoverCheckId,
            room: room.rawValue,
            imageData: imageData,
            caption: caption,
            beforeAfterType: beforeAfterType.rawValue,
            notes: notes,
            flagIssue: flagIssue
        )
    }

    func resetCaption() {
        caption = ""
        notes = ""
        flagIssue = false
    }
}

@MainActor
final class IssueFormViewModel: ObservableObject {
    @Published var title: String
    @Published var room: ChecklistSection
    @Published var issueDescription: String
    @Published var category: IssueCategory
    @Published var severity: IssueSeverity
    @Published var suggestedAction: String
    @Published var assignedAction: String
    @Published var status: IssueStatus

    init(issue: StayIssue? = nil) {
        self.title = issue?.title ?? ""
        self.room = ChecklistSection(rawValue: issue?.room ?? "") ?? .kitchen
        self.issueDescription = issue?.issueDescription ?? ""
        self.category = IssueCategory(rawValue: issue?.category ?? "") ?? .cleaningIssue
        self.severity = IssueSeverity(rawValue: issue?.severity ?? "") ?? .low
        self.suggestedAction = issue?.suggestedAction ?? ""
        self.assignedAction = issue?.assignedAction ?? ""
        self.status = IssueStatus(rawValue: issue?.status ?? "") ?? .open
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func makeIssue(propertyId: UUID, turnoverCheckId: UUID? = nil, photoId: UUID? = nil) -> StayIssue {
        StayIssue(
            propertyId: propertyId,
            turnoverCheckId: turnoverCheckId,
            photoId: photoId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            room: room.rawValue,
            issueDescription: issueDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.rawValue,
            severity: severity.rawValue,
            suggestedAction: suggestedAction.trimmingCharacters(in: .whitespacesAndNewlines),
            assignedAction: assignedAction.trimmingCharacters(in: .whitespacesAndNewlines),
            status: status.rawValue
        )
    }

    func apply(to issue: StayIssue) {
        issue.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        issue.room = room.rawValue
        issue.issueDescription = issueDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        issue.category = category.rawValue
        issue.severity = severity.rawValue
        issue.suggestedAction = suggestedAction.trimmingCharacters(in: .whitespacesAndNewlines)
        issue.assignedAction = assignedAction.trimmingCharacters(in: .whitespacesAndNewlines)
        issue.status = status.rawValue
    }
}

@MainActor
final class InventoryFormViewModel: ObservableObject {
    @Published var name: String
    @Published var category: InventoryCategory
    @Published var currentQuantity: Int
    @Published var minimumQuantity: Int
    @Published var needsRestock: Bool
    @Published var notes: String

    init(item: InventoryItem? = nil) {
        self.name = item?.name ?? ""
        self.category = InventoryCategory(rawValue: item?.category ?? "") ?? .towels
        self.currentQuantity = item?.currentQuantity ?? 0
        self.minimumQuantity = item?.minimumQuantity ?? 1
        self.needsRestock = item?.needsRestock ?? false
        self.notes = item?.notes ?? ""
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func makeItem(propertyId: UUID) -> InventoryItem {
        InventoryItem(
            propertyId: propertyId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.rawValue,
            currentQuantity: currentQuantity,
            minimumQuantity: minimumQuantity,
            needsRestock: needsRestock || currentQuantity < minimumQuantity,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func apply(to item: InventoryItem) {
        item.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        item.category = category.rawValue
        item.currentQuantity = currentQuantity
        item.minimumQuantity = minimumQuantity
        item.needsRestock = needsRestock || currentQuantity < minimumQuantity
        item.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
final class ReportGenerationViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var generatedURL: URL?

    func generate(input: PDFReportInput, services: AppServices) async -> URL? {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let url = try services.pdfService.generateReport(from: input)
            generatedURL = url
            return url
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
