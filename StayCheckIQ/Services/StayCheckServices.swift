import Foundation
import SwiftUI
import UIKit
import UserNotifications

let stayCheckInternalAIPrompt = """
You are StayCheck IQ, an assistant for Airbnb and short-let turnover inspections. Review room photos, checklist notes, property type, and inventory details. Identify visible cleanliness issues, possible damage, missing items, restock needs, and maintenance concerns. Do not claim legal certification, safety certification, or guaranteed guest satisfaction. Use cautious professional language and return structured findings.
"""

struct RoomScanRequest: Codable {
    var propertyType: String
    var room: String
    var checklistNotes: String
    var imageBase64: String
}

struct AISuggestedIssue: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var category: String
    var severity: String
    var suggestedAction: String

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case category
        case severity
        case suggestedAction
    }
}

struct RoomScanResult: Codable {
    var issues: [AISuggestedIssue]
    var guestReadyScore: Int
    var summary: String
    var suggestedNextAction: String
}

struct GuestReadyAssessment: Codable {
    var score: Int
    var status: GuestReadyStatus
    var summary: String
    var blockers: [String]
}

struct ReportTextInput {
    var propertyName: String
    var cleanerName: String
    var completedChecklistCount: Int
    var totalChecklistCount: Int
    var openIssueCount: Int
    var restockCount: Int
    var guestReadyAssessment: GuestReadyAssessment
}

protocol AIService {
    func scanRoomPhoto(_ request: RoomScanRequest) async throws -> RoomScanResult
    func generateTurnoverSummary(check: TurnoverCheck, issues: [StayIssue], inventory: [InventoryItem]) async throws -> String
    func generateGuestReadyScore(checklistItems: [TurnoverChecklistItem], issues: [StayIssue], photos: [RoomPhoto], inventory: [InventoryItem]) async throws -> GuestReadyAssessment
    func generateRestockSuggestions(inventory: [InventoryItem]) async throws -> [String]
    func generateReportText(_ input: ReportTextInput) async throws -> String
}

struct MockAIService: AIService {
    func scanRoomPhoto(_ request: RoomScanRequest) async throws -> RoomScanResult {
        try await Task.sleep(nanoseconds: 350_000_000)

        let notes = request.checklistNotes.lowercased()
        let room = request.room.lowercased()
        var issues: [AISuggestedIssue] = []

        if notes.contains("stain") || notes.contains("dirty") || notes.contains("mark") {
            issues.append(AISuggestedIssue(
                title: "Visible cleaning follow-up",
                description: "The notes mention a possible mark or stain. Review the area in person before marking the room guest-ready.",
                category: IssueCategory.cleaningIssue.rawValue,
                severity: IssueSeverity.medium.rawValue,
                suggestedAction: "Re-clean the affected surface and add an after photo."
            ))
        }

        if notes.contains("missing") || notes.contains("broken") || notes.contains("damage") {
            issues.append(AISuggestedIssue(
                title: "Possible damage or missing item",
                description: "The notes suggest something may be missing or damaged. Confirm against the property inventory.",
                category: IssueCategory.damage.rawValue,
                severity: IssueSeverity.high.rawValue,
                suggestedAction: "Create a maintenance issue with photo evidence and assign an owner."
            ))
        }

        if room.contains("bathroom") {
            issues.append(AISuggestedIssue(
                title: "Check bathroom consumables",
                description: "Confirm toilet paper, soap, shampoo, towels, bin liner, and visible surface finish before check-in.",
                category: IssueCategory.bathroomIssue.rawValue,
                severity: IssueSeverity.low.rawValue,
                suggestedAction: "Restock bathroom essentials if they are below the minimum level."
            ))
        } else if room.contains("kitchen") {
            issues.append(AISuggestedIssue(
                title: "Verify kitchen reset",
                description: "Review worktops, hob, sink, bins, tea and coffee, and high-touch handles for guest-readiness.",
                category: IssueCategory.kitchenIssue.rawValue,
                severity: IssueSeverity.low.rawValue,
                suggestedAction: "Add an after photo of the worktop and refresh low-stock items."
            ))
        }

        let score = max(45, 92 - (issues.count * 12))
        let nextAction = issues.contains { $0.severity == IssueSeverity.high.rawValue || $0.severity == IssueSeverity.urgent.rawValue }
            ? "Review and resolve high-severity findings before releasing the property."
            : "Complete any restock checks and capture final after photos."

        return RoomScanResult(
            issues: issues,
            guestReadyScore: score,
            summary: issues.isEmpty
                ? "No obvious issue was suggested by the mock scan. A human review is still required."
                : "Mock AI found \(issues.count) item(s) that should be reviewed before check-in.",
            suggestedNextAction: nextAction
        )
    }

    func generateTurnoverSummary(check: TurnoverCheck, issues: [StayIssue], inventory: [InventoryItem]) async throws -> String {
        let openIssues = issues.filter { $0.status != IssueStatus.resolved.rawValue }
        let restocks = inventory.filter { $0.currentQuantity < $0.minimumQuantity || $0.needsRestock }
        return "Turnover check by \(check.cleanerName.isEmpty ? "Unassigned cleaner" : check.cleanerName). \(openIssues.count) open issue(s), \(restocks.count) restock item(s), current score \(check.guestReadyScore). AI findings require human review."
    }

    func generateGuestReadyScore(checklistItems: [TurnoverChecklistItem], issues: [StayIssue], photos: [RoomPhoto], inventory: [InventoryItem]) async throws -> GuestReadyAssessment {
        GuestReadyCalculator.assess(
            checklistItems: checklistItems,
            issues: issues,
            photos: photos,
            inventory: inventory
        )
    }

    func generateRestockSuggestions(inventory: [InventoryItem]) async throws -> [String] {
        inventory
            .filter { $0.currentQuantity < $0.minimumQuantity || $0.needsRestock }
            .map { "\($0.name): restock to at least \($0.minimumQuantity)." }
    }

    func generateReportText(_ input: ReportTextInput) async throws -> String {
        """
        \(input.propertyName) turnover report: \(input.completedChecklistCount)/\(input.totalChecklistCount) checklist items complete, \(input.openIssueCount) open issue(s), \(input.restockCount) inventory restock item(s). Guest-ready result: \(input.guestReadyAssessment.status.rawValue) with score \(input.guestReadyAssessment.score). AI suggestions are review-only and do not certify safety, legality, or guest satisfaction.
        """
    }
}

struct RemoteAIService: AIService {
    private let endpoint = URL(string: "https://YOUR_BACKEND_URL.com/staycheck-iq")!
    private let fallback = MockAIService()

    private struct RemoteRoomScanResponse: Decodable {
        var issues: [AISuggestedIssue]
        var guestReadyScore: Int
        var summary: String
    }

    enum RemoteAIError: LocalizedError {
        case invalidResponse

        var errorDescription: String? {
            "The AI service returned an invalid response."
        }
    }

    func scanRoomPhoto(_ request: RoomScanRequest) async throws -> RoomScanResult {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw RemoteAIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(RemoteRoomScanResponse.self, from: data)
        return RoomScanResult(
            issues: decoded.issues,
            guestReadyScore: decoded.guestReadyScore,
            summary: decoded.summary,
            suggestedNextAction: decoded.issues.isEmpty
                ? "Complete the final human review."
                : "Review the suggested findings and resolve blockers before check-in."
        )
    }

    func generateTurnoverSummary(check: TurnoverCheck, issues: [StayIssue], inventory: [InventoryItem]) async throws -> String {
        try await fallback.generateTurnoverSummary(check: check, issues: issues, inventory: inventory)
    }

    func generateGuestReadyScore(checklistItems: [TurnoverChecklistItem], issues: [StayIssue], photos: [RoomPhoto], inventory: [InventoryItem]) async throws -> GuestReadyAssessment {
        try await fallback.generateGuestReadyScore(checklistItems: checklistItems, issues: issues, photos: photos, inventory: inventory)
    }

    func generateRestockSuggestions(inventory: [InventoryItem]) async throws -> [String] {
        try await fallback.generateRestockSuggestions(inventory: inventory)
    }

    func generateReportText(_ input: ReportTextInput) async throws -> String {
        try await fallback.generateReportText(input)
    }
}

struct NotificationService {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleRestockReminder(for item: InventoryItem, propertyName: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Restock \(item.name)"
        content.body = "\(propertyName) is below the minimum stock level for \(item.name)."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 12 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: "restock-\(item.id.uuidString)", content: content, trigger: trigger)
        try await center.add(request)
    }
}

struct PDFReportInput {
    var property: RentalProperty
    var check: TurnoverCheck
    var checklistItems: [TurnoverChecklistItem]
    var photos: [RoomPhoto]
    var issues: [StayIssue]
    var inventory: [InventoryItem]
    var assessment: GuestReadyAssessment
    var summary: String
}

struct PDFReportService {
    @MainActor
    func generateReport(from input: PDFReportInput) throws -> URL {
        let fileName = "StayCheck-\(input.property.name.sanitizedFileName)-\(Date.stayCheckFileStamp).pdf"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        try renderer.writePDF(to: url) { context in
            context.beginPage()

            var y: CGFloat = 42
            let margin: CGFloat = 44
            let contentWidth = pageRect.width - (margin * 2)

            func drawText(_ text: String, font: UIFont = .systemFont(ofSize: 12), color: UIColor = .label, spacing: CGFloat = 8) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                let rect = NSString(string: text).boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                if y + rect.height > pageRect.height - 56 {
                    context.beginPage()
                    y = 42
                }
                NSString(string: text).draw(
                    with: CGRect(x: margin, y: y, width: contentWidth, height: ceil(rect.height)),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                y += ceil(rect.height) + spacing
            }

            func drawDivider() {
                if y > pageRect.height - 64 {
                    context.beginPage()
                    y = 42
                }
                UIColor.systemGray4.setStroke()
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
                path.stroke()
                y += 14
            }

            drawText("StayCheck IQ Turnover Report", font: .boldSystemFont(ofSize: 24), color: .stayTealUIColor, spacing: 14)
            drawText(input.property.name, font: .boldSystemFont(ofSize: 18))
            drawText(input.property.address)
            drawText("Turnover date: \(input.check.date.formatted(date: .abbreviated, time: .shortened))")
            drawText("Cleaner: \(input.check.cleanerName.isEmpty ? "Unassigned" : input.check.cleanerName)")
            drawText("Guest-ready score: \(input.assessment.score) - \(input.assessment.status.rawValue)", font: .boldSystemFont(ofSize: 14))
            drawDivider()

            drawText("Summary", font: .boldSystemFont(ofSize: 16))
            drawText(input.summary)
            drawDivider()

            drawText("Completed Checklist", font: .boldSystemFont(ofSize: 16))
            for item in input.checklistItems.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                let marker = item.completed ? "[x]" : "[ ]"
                drawText("\(marker) \(item.section): \(item.title)")
            }
            drawDivider()

            drawText("Open Issues", font: .boldSystemFont(ofSize: 16))
            let openIssues = input.issues.filter { $0.status != IssueStatus.resolved.rawValue }
            if openIssues.isEmpty {
                drawText("No open issues recorded.")
            } else {
                for issue in openIssues {
                    drawText("\(issue.severity) - \(issue.title)", font: .boldSystemFont(ofSize: 12))
                    drawText("\(issue.category): \(issue.issueDescription) Action: \(issue.suggestedAction)")
                }
            }
            drawDivider()

            drawText("Inventory Notes", font: .boldSystemFont(ofSize: 16))
            let restockItems = input.inventory.filter { $0.currentQuantity < $0.minimumQuantity || $0.needsRestock }
            if restockItems.isEmpty {
                drawText("No restock blockers recorded.")
            } else {
                for item in restockItems {
                    drawText("\(item.name): \(item.currentQuantity)/\(item.minimumQuantity) minimum. \(item.notes)")
                }
            }
            drawDivider()

            drawText("Photo Evidence", font: .boldSystemFont(ofSize: 16))
            let previewPhotos = input.photos.prefix(6)
            if previewPhotos.isEmpty {
                drawText("No photo evidence added.")
            } else {
                for photo in previewPhotos {
                    drawText("\(photo.room) - \(photo.beforeAfterType): \(photo.caption)")
                    if let data = photo.imageData, let image = UIImage(data: data) {
                        if y + 130 > pageRect.height - 56 {
                            context.beginPage()
                            y = 42
                        }
                        let maxSize = CGSize(width: 160, height: 120)
                        let ratio = min(maxSize.width / image.size.width, maxSize.height / image.size.height)
                        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
                        image.draw(in: CGRect(x: margin, y: y, width: size.width, height: size.height))
                        y += size.height + 12
                    }
                }
            }
            drawDivider()

            drawText("Signature", font: .boldSystemFont(ofSize: 16))
            drawText("Cleaner signature: ______________________________")
            drawText("Host/manager review: ___________________________")
            drawDivider()

            drawText("Disclaimer", font: .boldSystemFont(ofSize: 16))
            drawText("AI findings must be reviewed. This report is not a legal property inspection, not safety certification, and not a replacement for qualified maintenance professionals. Urgent safety concerns should be checked immediately.")
        }

        return url
    }
}

@MainActor
final class AppServices: ObservableObject {
    let aiService: any AIService
    let remoteAIService = RemoteAIService()
    let pdfService = PDFReportService()
    let notificationService = NotificationService()

    init(aiService: any AIService = MockAIService()) {
        self.aiService = aiService
    }
}
