import Foundation
import SwiftUI
import UIKit

extension Color {
    static let stayTeal = Color(red: 0.0, green: 0.588, blue: 0.533)
    static let stayCharcoal = Color(red: 0.12, green: 0.14, blue: 0.16)
    static let staySoftTeal = Color(red: 0.88, green: 0.97, blue: 0.95)
    static let stayAmber = Color(red: 0.95, green: 0.60, blue: 0.20)
    static let stayRed = Color(red: 0.82, green: 0.20, blue: 0.24)
}

extension UIColor {
    static let stayTealUIColor = UIColor(red: 0.0, green: 0.588, blue: 0.533, alpha: 1.0)
}

extension String {
    var sanitizedFileName: String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .prefix(64)
            .description
    }
}

extension Date {
    static var stayCheckFileStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return formatter.string(from: Date())
    }

    static func todayAt(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}

extension Collection {
    var isNotEmpty: Bool {
        !isEmpty
    }
}

enum ChecklistTemplate {
    static func makeDefaultItems(for turnoverCheckId: UUID) -> [TurnoverChecklistItem] {
        let rows: [(ChecklistSection, String, Bool)] = [
            (.kitchen, "Worktops, hob, sink, fridge, bins, and handles cleaned", true),
            (.kitchen, "Tea, coffee, washing-up liquid, and bin bags restocked", false),
            (.bathroom, "Toilet, shower, mirrors, taps, floors, and bins cleaned", true),
            (.bathroom, "Toilet paper, soap, shampoo, and towels restocked", false),
            (.bedroom, "Beds made, linen checked, wardrobe and surfaces reset", true),
            (.bedroom, "Under-bed and bedside areas checked for guest items", false),
            (.livingRoom, "Sofa, tables, remote controls, and visible surfaces cleaned", true),
            (.livingRoom, "TV, Wi-Fi card, and guest guide positioned correctly", false),
            (.hallway, "Entry area, floors, keys, and access instructions checked", false),
            (.exterior, "Entrance, bins, balcony, or garden checked", true),
            (.linen, "Used linen removed and replacement sets counted", false),
            (.inventory, "Core inventory counted against minimum stock levels", false),
            (.safetyItems, "Smoke/CO alarm presence, fire blanket, and exits visually checked", false),
            (.customArea, "Any property-specific instructions completed", false)
        ]

        return rows.enumerated().map { index, row in
            TurnoverChecklistItem(
                turnoverCheckId: turnoverCheckId,
                section: row.0.rawValue,
                title: row.1,
                photoRequired: row.2,
                sortOrder: index
            )
        }
    }

    static func starterInventory(for propertyId: UUID) -> [InventoryItem] {
        [
            InventoryItem(propertyId: propertyId, name: "Bath towels", category: InventoryCategory.towels.rawValue, currentQuantity: 6, minimumQuantity: 4),
            InventoryItem(propertyId: propertyId, name: "Bedding sets", category: InventoryCategory.bedding.rawValue, currentQuantity: 3, minimumQuantity: 2),
            InventoryItem(propertyId: propertyId, name: "Toilet paper rolls", category: InventoryCategory.toiletPaper.rawValue, currentQuantity: 8, minimumQuantity: 6),
            InventoryItem(propertyId: propertyId, name: "Hand soap", category: InventoryCategory.soap.rawValue, currentQuantity: 2, minimumQuantity: 2),
            InventoryItem(propertyId: propertyId, name: "Shampoo", category: InventoryCategory.shampoo.rawValue, currentQuantity: 2, minimumQuantity: 2),
            InventoryItem(propertyId: propertyId, name: "Tea and coffee", category: InventoryCategory.teaCoffee.rawValue, currentQuantity: 12, minimumQuantity: 8),
            InventoryItem(propertyId: propertyId, name: "Cleaning products", category: InventoryCategory.cleaningProducts.rawValue, currentQuantity: 3, minimumQuantity: 2),
            InventoryItem(propertyId: propertyId, name: "Remote batteries", category: InventoryCategory.batteries.rawValue, currentQuantity: 4, minimumQuantity: 2),
            InventoryItem(propertyId: propertyId, name: "Spare keys", category: InventoryCategory.keys.rawValue, currentQuantity: 2, minimumQuantity: 1),
            InventoryItem(propertyId: propertyId, name: "TV remotes", category: InventoryCategory.remotes.rawValue, currentQuantity: 1, minimumQuantity: 1),
            InventoryItem(propertyId: propertyId, name: "Kitchen essentials", category: InventoryCategory.kitchenItems.rawValue, currentQuantity: 1, minimumQuantity: 1)
        ]
    }
}

enum GuestReadyCalculator {
    static func assess(
        checklistItems: [TurnoverChecklistItem],
        issues: [StayIssue],
        photos: [RoomPhoto],
        inventory: [InventoryItem]
    ) -> GuestReadyAssessment {
        let total = max(checklistItems.count, 1)
        let completedRatio = Double(checklistItems.filter(\.completed).count) / Double(total)
        let cleanRatio = Double(checklistItems.filter(\.cleaned).count) / Double(total)
        let guestReadyRatio = Double(checklistItems.filter(\.guestReady).count) / Double(total)
        let requiredPhotoCount = max(checklistItems.filter(\.photoRequired).count, 1)
        let photoRatio = min(Double(photos.count) / Double(requiredPhotoCount), 1.0)

        let openIssues = issues.filter { $0.status != IssueStatus.resolved.rawValue }
        let restockItems = inventory.filter { $0.currentQuantity < $0.minimumQuantity || $0.needsRestock }

        let issuePenalty = openIssues.reduce(0) { result, issue in
            switch IssueSeverity(rawValue: issue.severity) ?? .low {
            case .low: return result + 3
            case .medium: return result + 7
            case .high: return result + 14
            case .urgent: return result + 24
            }
        }

        let rawScore = Int(
            (completedRatio * 42) +
            (cleanRatio * 16) +
            (guestReadyRatio * 18) +
            (photoRatio * 16) +
            8
        ) - issuePenalty - (restockItems.count * 5)

        let score = min(max(rawScore, 0), 100)
        let hasSevereBlocker = openIssues.contains {
            let severity = IssueSeverity(rawValue: $0.severity) ?? .low
            return severity == .high || severity == .urgent
        }

        let status: GuestReadyStatus
        if score >= 85 && !hasSevereBlocker && restockItems.isEmpty {
            status = .ready
        } else if score >= 65 && !openIssues.contains(where: { (IssueSeverity(rawValue: $0.severity) ?? .low) == .urgent }) {
            status = .needsReview
        } else {
            status = .notReady
        }

        var blockers: [String] = []
        if hasSevereBlocker {
            blockers.append("High or urgent issue requires review.")
        }
        if restockItems.isNotEmpty {
            blockers.append("\(restockItems.count) inventory item(s) below minimum stock.")
        }
        if checklistItems.contains(where: { !$0.completed }) {
            blockers.append("Checklist is not fully complete.")
        }
        if photos.isEmpty {
            blockers.append("No photo evidence added.")
        }

        let summary: String
        switch status {
        case .ready:
            summary = "Ready for guest arrival after final human review."
        case .needsReview:
            summary = "Needs manager or host review before release."
        case .notReady:
            summary = "Not ready until blocking issues are resolved."
        }

        return GuestReadyAssessment(score: score, status: status, summary: summary, blockers: blockers)
    }
}

enum PlanPolicy {
    static func canAddProperty(currentCount: Int, plan: SubscriptionPlan) -> Bool {
        switch plan {
        case .free:
            return currentCount < 1
        case .pro:
            return currentCount < 5
        case .business:
            return true
        }
    }

    static func propertyLimitText(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .free:
            return "1 property"
        case .pro:
            return "Up to 5 properties"
        case .business:
            return "Unlimited properties"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
